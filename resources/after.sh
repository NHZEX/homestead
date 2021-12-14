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

# Ubuntu apt 源
#sudo sed -i 's/archive.ubuntu.com/mirrors.tuna.tsinghua.edu.cn/g' /etc/apt/sources.list
#sudo sed -i 's/security.ubuntu.com/mirrors.tuna.tsinghua.edu.cn/g' /etc/apt/sources.list

# Composer 源
#composer config -g repo.packagist composer https://mirrors.aliyun.com/composer/

# Nodejs 源
#npm set registry https://registry.npmmirror.com
#npm set disturl https://npmmirror.com/dist # node-gyp 编译依赖的 node 源码
#npm set sass_binary_site https://npmmirror.com/mirrors/node-sass
#npm set electron_mirror https://npmmirror.com/mirrors/electron/
#npm set puppeteer_download_host https://npmmirror.com/mirrors
#npm set chromedriver_cdnurl https://npmmirror.com/mirrors/chromedriver
#npm set operadriver_cdnurl https://npmmirror.com/mirrors/operadriver
#npm set phantomjs_cdnurl https://npmmirror.com/mirrors/phantomjs
#npm set selenium_cdnurl https://npmmirror.com/mirrors/selenium
#npm set node_inspector_cdnurl https://npmmirror.com/mirrors/node-inspector

#yarn config set registry https://registry.npmmirror.com
#yarn config set disturl https://npmmirror.com/dist # node-gyp 编译依赖的 node 源码
#yarn config set sass_binary_site https://npmmirror.com/mirrors/node-sass
#yarn config set electron_mirror https://npmmirror.com/mirrors/electron/
#yarn config set puppeteer_download_host https://npmmirror.com/mirrors
#yarn config set chromedriver_cdnurl https://npmmirror.com/mirrors/chromedriver
#yarn config set operadriver_cdnurl https://npmmirror.com/mirrors/operadriver
#yarn config set phantomjs_cdnurl https://npmmirror.com/mirrors/phantomjs
#yarn config set selenium_cdnurl https://npmmirror.com/mirrors/selenium
#yarn config set node_inspector_cdnurl https://npmmirror.com/mirrors/node-inspector

#pnpm config set registry https://registry.npmmirror.com
#pnpm config set disturl https://npmmirror.com/dist
#pnpm config set sass_binary_site https://npmmirror.com/mirrors/node-sass
#pnpm config set electron_mirror https://npmmirror.com/mirrors/electron/
#pnpm config set puppeteer_download_host https://npmmirror.com/mirrors
#pnpm config set chromedriver_cdnurl https://npmmirror.com/mirrors/chromedriver
#pnpm config set operadriver_cdnurl https://npmmirror.com/mirrors/operadriver
#pnpm config set phantomjs_cdnurl https://npmmirror.com/mirrors/phantomjs
#pnpm config set selenium_cdnurl https://npmmirror.com/mirrors/selenium
#pnpm config set node_inspector_cdnurl https://npmmirror.com/mirrors/node-inspector
