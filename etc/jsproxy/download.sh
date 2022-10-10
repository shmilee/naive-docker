#!/bin/bash
# Copyright (C) 2022 shmilee

JSPROXY_VER="$1"
ZIP_URL=https://codeload.github.com/EtherDream/jsproxy/tar.gz

curl -o jsproxy.tar.gz $ZIP_URL/$JSPROXY_VER
tar zxf jsproxy.tar.gz
rm -f jsproxy.tar.gz

curl -o www.tar.gz $ZIP_URL/gh-pages
tar zxf www.tar.gz -C jsproxy-$JSPROXY_VER/www --strip-components=1
rm -f www.tar.gz
# add scholar
cp scholar.png jsproxy-$JSPROXY_VER/www/assets/ico/
patch -b -p1 -d jsproxy-$JSPROXY_VER/www -i ../../www-index_v3.patch
# edit cf-worker/index.js for /ws
patch -b -p1 -d jsproxy-$JSPROXY_VER/cf-worker -i ../../cf-worker-index.patch

# resty/?.lua
wget -c -O lua-resty-string.tar.gz https://github.com/openresty/lua-resty-string/archive/refs/tags/v0.15.tar.gz
tar zxf lua-resty-string.tar.gz
mv lua-resty-string-0.15/lib/resty jsproxy-$JSPROXY_VER/
rm -rf lua-resty-string.tar.gz lua-resty-string-0.15
