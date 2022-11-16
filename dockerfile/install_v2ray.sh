#!/bin/bash

V2RAY_VERSION=${1:-5.1.0}
V2RAY_LOCATION_ASSET=${V2RAY_LOCATION_ASSET:-/etc/v2ray}
V2RAY_ZIP_URL=${V2RAY_ZIP_URL:-'https://github.com/v2fly/v2ray-core/releases/download/v%s/v2ray-linux-64.zip'}
V2RAY_CACHE_ZIP=/srv/v2ray-linux-64-v${V2RAY_VERSION}.zip

if [ ! -f "${V2RAY_CACHE_ZIP}" ]; then
    wget -P /srv -O ${V2RAY_CACHE_ZIP} `printf "${V2RAY_ZIP_URL}" ${V2RAY_VERSION}`
fi

if [ -f ${V2RAY_CACHE_ZIP} ]; then
    echo "==> Using v2ray: $V2RAY_VERSION ..."
    mkdir /tmp/v2r
    unzip ${V2RAY_CACHE_ZIP} -d /tmp/v2r/ \
    && install -Dm755 -v /tmp/v2r/v2ray /usr/bin/v2ray \
    && install -Dm755 /tmp/v2r/geoip.dat ${V2RAY_LOCATION_ASSET}/geoip.dat \
    && install -Dm644 /tmp/v2r/geosite.dat ${V2RAY_LOCATION_ASSET}/geosite.dat \
    && install -Dm644 /tmp/v2r/config.json ${V2RAY_LOCATION_ASSET}/config.json
    rm -rf /tmp/v2r
fi
