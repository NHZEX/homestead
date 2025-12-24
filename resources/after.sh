#!/bin/sh

# If you would like to do some extra provisioning you may
# add any commands you wish to this file and they will
# be run after the Homestead machine is provisioned.
#
# If you have user-specific configurations you would like
# to apply, you may also create user-customizations.sh,
# which will be run after this script.


# If you're not quite ready for the latest Node.js version,
# uncomment these lines to roll back to a previous version

# Remove current Node.js version:
#sudo apt-get -y purge nodejs
#sudo rm -rf /usr/lib/node_modules/npm/lib
#sudo rm -rf //etc/apt/sources.list.d/nodesource.list

# Install Node.js Version desired (i.e. v13)
# More info: https://github.com/nodesource/distributions/blob/master/README.md#debinstall
#curl -sL https://deb.nodesource.com/setup_13.x | sudo -E bash -
#sudo apt-get install -y nodejs

# 自定义扩展

# ustc mirrors(DEB822)
sudo sed -i 's@//.*archive.ubuntu.com@//mirrors.ustc.edu.cn@g' /etc/apt/sources.list.d/ubuntu.sources
sudo sed -i 's/http:/https:/g' /etc/apt/sources.list.d/ubuntu.sources

# 代理配置变量（集中管理）
PROXY_HOST="192.168.10.1"
PROXY_PORT="7891"
PROXY_URL="http://${PROXY_HOST}:${PROXY_PORT}"
NO_PROXY="127.0.0.1,192.168.3.1,test"

echo "正在配置系统代理..."

# 1. 配置 APT 代理
echo "配置 APT 代理..."
sudo tee /etc/apt/apt.conf.d/99-proxy.conf > /dev/null <<EOF
Acquire::http::Proxy "${PROXY_URL}";
Acquire::https::Proxy "${PROXY_URL}";
EOF

# 2. 在 .bashrc 中添加代理函数（如果不存在）
BASHRC="/home/vagrant/.bashrc"

if ! grep -q "## Proxy Configuration" "$BASHRC"; then
    echo "添加代理管理函数到 .bashrc..."
    cat >> "$BASHRC" <<'EOF'

## Proxy Configuration
PROXY_HOST="192.168.10.1"
PROXY_PORT="7891"
PROXY_URL="http://${PROXY_HOST}:${PROXY_PORT}"
NO_PROXY="127.0.0.1,192.168.3.1,test"

# 代理开关函数
proxy_on() {
    export http_proxy="${PROXY_URL}"
    export https_proxy="${PROXY_URL}"
    export HTTP_PROXY="${PROXY_URL}"
    export HTTPS_PROXY="${PROXY_URL}"
    export no_proxy="${NO_PROXY}"
    export NO_PROXY="${NO_PROXY}"
    echo "✓ 代理已启用: ${PROXY_URL}"
}

proxy_off() {
    unset http_proxy
    unset https_proxy
    unset HTTP_PROXY
    unset HTTPS_PROXY
    unset no_proxy
    unset NO_PROXY
    echo "✓ 代理已禁用"
}

proxy_status() {
    if [ -n "$http_proxy" ]; then
        echo "proxy: on"
        echo "  http_proxy: $http_proxy"
        echo "  https_proxy: $https_proxy"
        echo "  no_proxy: $no_proxy"
    else
        echo "proxy: off"
    fi
}

# 默认启用代理
proxy_on
## Proxy Configuration End
EOF
fi
