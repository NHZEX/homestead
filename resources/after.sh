#!/bin/sh

# If you would like to do some extra provisioning you may
# add any commands you wish to this file and they will
# be run after the Homestead machine is provisioned.
#
# If you have user-specific configurations you would like
# to apply, you may also create user-customizations.sh,
# which will be run after this script.

# If you're not quite ready for Node 12.x
# Uncomment these lines to roll back to
# v11.x or v10.x

# Remove Node.js v12.x:
#sudo apt-get -y purge nodejs
#sudo rm -rf /usr/lib/node_modules/npm/lib
#sudo rm -rf //etc/apt/sources.list.d/nodesource.list

# Install Node.js v11.x
#curl -sL https://deb.nodesource.com/setup_11.x | sudo -E bash -
#sudo apt-get install -y nodejs

# Install Node.js v10.x
#curl -sL https://deb.nodesource.com/setup_10.x | sudo -E bash -
#sudo apt-get install -y nodejs

# Ubuntu apt 源
#sudo sed -i 's/archive.ubuntu.com/mirrors.tuna.tsinghua.edu.cn/g' /etc/apt/sources.list
#sudo sed -i 's/security.ubuntu.com/mirrors.tuna.tsinghua.edu.cn/g' /etc/apt/sources.list

# Composer 源
#composer config -g repo.packagist composer https://mirrors.aliyun.com/composer/

# Nodejs 源
#npm set registry https://registry.npm.taobao.org
#npm set disturl https://npm.taobao.org/dist # node-gyp 编译依赖的 node 源码
#npm set sass_binary_site https://npm.taobao.org/mirrors/node-sass
#npm set electron_mirror https://npm.taobao.org/mirrors/electron/
#npm set puppeteer_download_host https://npm.taobao.org/mirrors
#npm set chromedriver_cdnurl https://npm.taobao.org/mirrors/chromedriver
#npm set operadriver_cdnurl https://npm.taobao.org/mirrors/operadriver
#npm set phantomjs_cdnurl https://npm.taobao.org/mirrors/phantomjs
#npm set selenium_cdnurl https://npm.taobao.org/mirrors/selenium
#npm set node_inspector_cdnurl https://npm.taobao.org/mirrors/node-inspector

#yarn config set registry https://registry.npm.taobao.org
#yarn config set disturl https://npm.taobao.org/dist # node-gyp 编译依赖的 node 源码
#yarn config set sass_binary_site https://npm.taobao.org/mirrors/node-sass
#yarn config set electron_mirror https://npm.taobao.org/mirrors/electron/
#yarn config set puppeteer_download_host https://npm.taobao.org/mirrors
#yarn config set chromedriver_cdnurl https://npm.taobao.org/mirrors/chromedriver
#yarn config set operadriver_cdnurl https://npm.taobao.org/mirrors/operadriver
#yarn config set phantomjs_cdnurl https://npm.taobao.org/mirrors/phantomjs
#yarn config set selenium_cdnurl https://npm.taobao.org/mirrors/selenium
#yarn config set node_inspector_cdnurl https://npm.taobao.org/mirrors/node-inspector
