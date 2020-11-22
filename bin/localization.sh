export ALL_PROXY=socks5://192.168.3.8.10900
export all_proxy=socks5://192.168.3.8.10900
export http_proxy=http://192.168.3.8:10901
export https_proxy=http://192.168.3.8:10901
export no_proxy='127.0.0.1'

rm ~/apt_proxy.conf || true
echo -e "Acquire::http::Proxy \"${http_proxy}\";" | sudo tee -a ~/apt_proxy.conf > /dev/null
echo -e "Acquire::https::Proxy \"${http_proxy}\";" | sudo tee -a ~/apt_proxy.conf > /dev/null
export APT_CONFIG=~/apt_proxy.conf
