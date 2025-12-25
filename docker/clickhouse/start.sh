#!/usr/bin/env bash

set -euo pipefail

# * ClickHouse 启动入口（供 docker-apps.sh 自动调用）
# * 目的：准备宿主机目录权限（/opt/clickhouse/*），然后启动 compose

# * 配置变量（集中管理）
CLICKHOUSE_DATA_DIR="${CLICKHOUSE_DATA_DIR:-/opt/clickhouse/data}"
CLICKHOUSE_LOG_DIR="${CLICKHOUSE_LOG_DIR:-/opt/clickhouse/logs}"

# 创建 ClickHouse 专用用户与用户组
if ! id -g clickhouse &>/dev/null; then
    sudo groupadd -r clickhouse
fi
if ! id -u clickhouse &>/dev/null; then
    sudo useradd -r -M -s /bin/false -g clickhouse clickhouse
fi

# 查询ID
CLICKHOUSE_UID="$(id -u clickhouse)"
CLICKHOUSE_GID="$(id -g clickhouse)"

CLICKHOUSE_DIR_MODE="${CLICKHOUSE_DIR_MODE:-0755}"

log() {
  echo "[clickhouse][start] $*"
}

die() {
  echo "[clickhouse][start][ERROR] $*" >&2
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
  local dir="$1"
  local args=()

  args+=(-f docker-compose.yml)

  if [ -f "$dir/docker-compose.override.yml" ]; then
    args+=(-f docker-compose.override.yml)
  fi
  if [ -f "$dir/docker-compose.override.yaml" ]; then
    args+=(-f docker-compose.override.yaml)
  fi

  echo "${args[*]}"
}

prepare_dirs() {
  mkdir -p "$CLICKHOUSE_DATA_DIR" "$CLICKHOUSE_LOG_DIR"

  # * 让容器内 ClickHouse 进程可写入数据与日志目录
  chown -R "${CLICKHOUSE_UID}:${CLICKHOUSE_GID}" "$CLICKHOUSE_DATA_DIR" "$CLICKHOUSE_LOG_DIR" || true
  chmod "$CLICKHOUSE_DIR_MODE" "$CLICKHOUSE_DATA_DIR" "$CLICKHOUSE_LOG_DIR" || true
}

main() {
  local script_dir
  script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

  local compose_cmd
  if ! compose_cmd="$(detect_compose_cmd)"; then
    die "未找到 docker compose / docker-compose，请确认 VM 已安装 Docker Compose"
  fi

  prepare_dirs

  # * 导出 ClickHouse 专用用户与用户组 ID
  export CLICKHOUSE_UID CLICKHOUSE_GID

  # 导出包含 ClickHouse 专用用户与用户组 ID 的 env 文件，仅文件内不存用户ID和组ID在时才追加
  if ! grep -q "CLICKHOUSE_UID=" "$script_dir/.env"; then
    echo "CLICKHOUSE_UID=$CLICKHOUSE_UID" >> "$script_dir/.env"
  fi
  if ! grep -q "CLICKHOUSE_GID=" "$script_dir/.env"; then
    echo "CLICKHOUSE_GID=$CLICKHOUSE_GID" >> "$script_dir/.env"
  fi

  local compose_args
  compose_args="$(get_compose_args "$script_dir")"

  log "启动 ClickHouse（up -d）"
  # shellcheck disable=SC2086
  (cd "$script_dir" && $compose_cmd $compose_args up -d)
}

main "$@"


