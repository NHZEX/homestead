#!/usr/bin/env bash

set -euo pipefail

# * 根据 Homestead.yaml 的 docker_apps 配置，同步并启动/停止 Docker 全局服务
# * 约定：
# * - Host 侧目录：/vagrant/docker/<app>/
# * - VM 侧目录：/opt/.docker/<app>/
# * - 若存在 start.sh：优先执行（用于自定义启动逻辑）
# * - 若不存在 start.sh：默认执行 docker-compose.yml（docker compose up -d）
# * - 禁用仅 stop（不 down），避免误删资源

DOCKER_APPS_SOURCE="${DOCKER_APPS_SOURCE:-/vagrant/docker}"
DOCKER_APPS_DEST="${DOCKER_APPS_DEST:-/opt/.docker}"
DOCKER_APPS_ENABLED="${DOCKER_APPS_ENABLED:-}"
DOCKER_APPS_DISABLED="${DOCKER_APPS_DISABLED:-}"

# * 权限/所有者修正（用于把共享目录常见的 777 归一化）
# * 注意：默认将文件归属到 vagrant，方便在 VM 内直接修改运行目录（仍建议用 override 文件做本地覆写）
DOCKER_APPS_OWNER="${DOCKER_APPS_OWNER:-vagrant:vagrant}"
DOCKER_APPS_DIR_MODE="${DOCKER_APPS_DIR_MODE:-0755}"
DOCKER_APPS_FILE_MODE="${DOCKER_APPS_FILE_MODE:-0644}"
DOCKER_APPS_SH_MODE="${DOCKER_APPS_SH_MODE:-0755}"

log() {
  echo "[docker-apps] $*"
}

warn() {
  echo "[docker-apps][WARN] $*" >&2
}

die() {
  echo "[docker-apps][ERROR] $*" >&2
  exit 1
}

detect_compose_cmd() {
  if command -v docker >/dev/null 2>&1 && docker compose version >/dev/null 2>&1; then
    echo "docker compose"
    return 0
  fi

  if command -v docker-compose >/dev/null 2>&1; then
    echo "docker-compose"
    return 0
  fi

  return 1
}

get_compose_args() {
  local dst_dir="$1"
  local args=()

  # * 基础文件固定为 docker-compose.yml
  args+=(-f docker-compose.yml)

  # * 本地覆写：同步时会保护不覆盖/不删除，适合在 VM 内热修改
  if [ -f "$dst_dir/docker-compose.override.yml" ]; then
    args+=(-f docker-compose.override.yml)
  fi
  if [ -f "$dst_dir/docker-compose.override.yaml" ]; then
    args+=(-f docker-compose.override.yaml)
  fi

  echo "${args[*]}"
}

is_valid_app_name() {
  local app="$1"

  # * 防止目录穿越/注入：只允许字母数字开头，后续允许 . _ -
  if [[ ! "$app" =~ ^[A-Za-z0-9][A-Za-z0-9._-]*$ ]]; then
    return 1
  fi

  return 0
}

ensure_rsync() {
  if command -v rsync >/dev/null 2>&1; then
    return 0
  fi

  # ! 兜底：尽量安装 rsync 以便支持 exclude + delete（性能和可控性更好）
  if command -v apt-get >/dev/null 2>&1; then
    log "rsync 未安装，尝试通过 apt-get 安装..."
    export DEBIAN_FRONTEND=noninteractive
    apt-get --allow-releaseinfo-change update -y
    apt-get install -y rsync
  fi
}

fix_permissions() {
  local dst_dir="$1"

  if [ -z "$dst_dir" ] || [ "$dst_dir" = "/" ]; then
    die "目标目录非法（拒绝修正权限）：dst_dir='$dst_dir'"
  fi

  # * 允许目标目录在 VM 内被修改（默认归属 vagrant）
  chown -R "$DOCKER_APPS_OWNER" "$dst_dir" || true

  # * 归一化权限：目录 755、文件 644、脚本 755
  if command -v find >/dev/null 2>&1; then
    find "$dst_dir" -type d -exec chmod "$DOCKER_APPS_DIR_MODE" {} + || true
    find "$dst_dir" -type f -exec chmod "$DOCKER_APPS_FILE_MODE" {} + || true
    find "$dst_dir" -type f -name '*.sh' -exec chmod "$DOCKER_APPS_SH_MODE" {} + || true
  else
    # ! 极端兜底：缺少 find 时，至少移除 other 写权限，避免 777
    chmod -R o-w "$dst_dir" || true
  fi

  # * 明确保证 start/stop 可执行
  if [ -f "$dst_dir/start.sh" ]; then
    chmod +x "$dst_dir/start.sh" || true
  fi
  if [ -f "$dst_dir/stop.sh" ]; then
    chmod +x "$dst_dir/stop.sh" || true
  fi
}

sync_dir() {
  local src="$1"
  local dst="$2"

  if [ -z "$dst" ] || [ "$dst" = "/" ]; then
    die "目标目录非法（拒绝执行）：dst='$dst'"
  fi

  mkdir -p "$dst"

  ensure_rsync || true

  if command -v rsync >/dev/null 2>&1; then
    # * 仅同步内容（不依赖共享目录性能）
    # * 保护本地覆写文件：用于在 VM 内热修改且不被下一次 provision 覆盖
    rsync -a --delete \
      --exclude '.git' \
      --exclude 'node_modules' \
      --exclude '.DS_Store' \
      --exclude '.local/**' \
      --exclude '.env' \
      --exclude '.env.local' \
      --exclude 'docker-compose.override.yml' \
      --exclude 'docker-compose.override.yaml' \
      "$src"/ "$dst"/
    return 0
  fi

  # ! 兜底：没有 rsync 时使用 cp（不保证删除已移除的文件）
  # ! 仅清理“基础文件”，尽量保留本地覆写文件
  find "$dst" -mindepth 1 -maxdepth 1 \
    ! -name '.local' \
    ! -name '.env' \
    ! -name '.env.local' \
    ! -name 'docker-compose.override.yml' \
    ! -name 'docker-compose.override.yaml' \
    -exec rm -rf {} + || true

  cp -a "$src"/. "$dst"/
}

run_enabled_app() {
  local app="$1"
  local src_dir="${DOCKER_APPS_SOURCE%/}/$app"
  local dst_dir="${DOCKER_APPS_DEST%/}/$app"

  if ! is_valid_app_name "$app"; then
    warn "应用名非法，跳过：$app"
    return 0
  fi

  if [ ! -d "$src_dir" ]; then
    warn "未找到应用目录，跳过启动：$src_dir"
    return 0
  fi

  log "同步：$src_dir -> $dst_dir"
  sync_dir "$src_dir" "$dst_dir"
  fix_permissions "$dst_dir"

  if [ -f "$dst_dir/start.sh" ]; then
    log "执行自定义 start.sh：$app"
    (cd "$dst_dir" && bash "./start.sh")
    return 0
  fi

  if [ ! -f "$dst_dir/docker-compose.yml" ]; then
    warn "未找到 docker-compose.yml，跳过启动：$dst_dir/docker-compose.yml"
    return 0
  fi

  local compose_cmd
  if ! compose_cmd="$(detect_compose_cmd)"; then
    die "未找到 docker compose / docker-compose，请确认 VM 已安装 Docker Compose"
  fi

  local compose_args
  compose_args="$(get_compose_args "$dst_dir")"

  log "启动（up -d）：$app"
  # shellcheck disable=SC2086
  (cd "$dst_dir" && $compose_cmd $compose_args up -d)
}

stop_disabled_app() {
  local app="$1"
  local dst_dir="${DOCKER_APPS_DEST%/}/$app"

  if ! is_valid_app_name "$app"; then
    warn "应用名非法，跳过：$app"
    return 0
  fi

  if [ ! -d "$dst_dir" ]; then
    log "禁用 stop：$app（目录不存在，跳过）"
    return 0
  fi

  if [ -f "$dst_dir/stop.sh" ]; then
    log "执行自定义 stop.sh：$app"
    chmod +x "$dst_dir/stop.sh" || true
    (cd "$dst_dir" && bash "./stop.sh")
    return 0
  fi

  if [ ! -f "$dst_dir/docker-compose.yml" ]; then
    warn "禁用 stop：$app（未找到 docker-compose.yml / stop.sh，跳过）"
    return 0
  fi

  local compose_cmd
  if ! compose_cmd="$(detect_compose_cmd)"; then
    warn "禁用 stop：$app（未找到 docker compose / docker-compose，跳过）"
    return 0
  fi

  local compose_args
  compose_args="$(get_compose_args "$dst_dir")"

  log "停止（stop）：$app"
  # shellcheck disable=SC2086
  (cd "$dst_dir" && $compose_cmd $compose_args stop) || true
}

usage() {
  cat <<'EOF'
用法：
  docker-apps.sh provision
  docker-apps.sh start <app> [app...]
  docker-apps.sh stop <app> [app...]
  docker-apps.sh restart <app> [app...]
  docker-apps.sh sync <app> [app...]
  docker-apps.sh list
  docker-apps.sh help

说明：
  - provision：由 Homestead provision 调用，读取 DOCKER_APPS_ENABLED / DOCKER_APPS_DISABLED。
  - start：同步 /vagrant/docker/<app> 到 /opt/.docker/<app>，再执行 start.sh（若存在）或 docker compose up -d。
  - stop：优先执行 stop.sh（若存在），否则 docker compose stop；不会 down。
  - sync：仅同步与权限修正，不启动容器。
  - list：列出源目录下可用 app 名称（目录名）。

可选环境变量：
  DOCKER_APPS_SOURCE=/vagrant/docker
  DOCKER_APPS_DEST=/opt/.docker
  DOCKER_APPS_OWNER=vagrant:vagrant
  DOCKER_APPS_DIR_MODE=0755
  DOCKER_APPS_FILE_MODE=0644
  DOCKER_APPS_SH_MODE=0755
EOF
}

list_apps() {
  if [ ! -d "$DOCKER_APPS_SOURCE" ]; then
    warn "源目录不存在：$DOCKER_APPS_SOURCE"
    return 0
  fi

  find "$DOCKER_APPS_SOURCE" -mindepth 1 -maxdepth 1 -type d -printf '%f\n' | sort
}

sync_one_app() {
  local app="$1"
  local src_dir="${DOCKER_APPS_SOURCE%/}/$app"
  local dst_dir="${DOCKER_APPS_DEST%/}/$app"

  if ! is_valid_app_name "$app"; then
    warn "应用名非法，跳过：$app"
    return 0
  fi

  if [ ! -d "$src_dir" ]; then
    warn "未找到应用目录，跳过同步：$src_dir"
    return 0
  fi

  log "同步：$src_dir -> $dst_dir"
  sync_dir "$src_dir" "$dst_dir"
  fix_permissions "$dst_dir"
}

provision_main() {
  mkdir -p "$DOCKER_APPS_DEST"

  # * 以空格分隔（由 Ruby 侧 join(' ') 注入）
  local enabled_apps=()
  local disabled_apps=()

  if [ -n "${DOCKER_APPS_ENABLED// }" ]; then
    read -r -a enabled_apps <<< "$DOCKER_APPS_ENABLED"
  fi

  if [ -n "${DOCKER_APPS_DISABLED// }" ]; then
    read -r -a disabled_apps <<< "$DOCKER_APPS_DISABLED"
  fi

  if [ "${#enabled_apps[@]}" -eq 0 ] && [ "${#disabled_apps[@]}" -eq 0 ]; then
    log "未配置 docker_apps 或列表为空，跳过"
    return 0
  fi

  log "目标目录：$DOCKER_APPS_DEST"
  log "源目录：$DOCKER_APPS_SOURCE"

  if [ "${#enabled_apps[@]}" -gt 0 ]; then
    log "启用：${enabled_apps[*]}"
    for app in "${enabled_apps[@]}"; do
      run_enabled_app "$app"
    done
  fi

  if [ "${#disabled_apps[@]}" -gt 0 ]; then
    log "禁用（仅 stop）：${disabled_apps[*]}"
    for app in "${disabled_apps[@]}"; do
      stop_disabled_app "$app"
    done
  fi
}

cli_main() {
  local cmd="${1:-provision}"

  case "$cmd" in
    help|-h|--help)
      usage
      return 0
      ;;
    list)
      shift || true
      list_apps
      return 0
      ;;
    provision)
      shift || true
      provision_main
      return 0
      ;;
    start)
      shift || true
      if [ "$#" -lt 1 ]; then
        die "缺少 app 参数，用法：docker-apps.sh start <app> [app...]"
      fi
      for app in "$@"; do
        run_enabled_app "$app"
      done
      return 0
      ;;
    stop)
      shift || true
      if [ "$#" -lt 1 ]; then
        die "缺少 app 参数，用法：docker-apps.sh stop <app> [app...]"
      fi
      for app in "$@"; do
        stop_disabled_app "$app"
      done
      return 0
      ;;
    restart)
      shift || true
      if [ "$#" -lt 1 ]; then
        die "缺少 app 参数，用法：docker-apps.sh restart <app> [app...]"
      fi
      for app in "$@"; do
        stop_disabled_app "$app"
        run_enabled_app "$app"
      done
      return 0
      ;;
    sync)
      shift || true
      if [ "$#" -lt 1 ]; then
        die "缺少 app 参数，用法：docker-apps.sh sync <app> [app...]"
      fi
      for app in "$@"; do
        sync_one_app "$app"
      done
      return 0
      ;;
    *)
      usage
      die "未知命令：$cmd"
      ;;
  esac
}

cli_main "$@"


