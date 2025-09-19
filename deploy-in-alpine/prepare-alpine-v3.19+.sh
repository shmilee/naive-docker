#!/bin/ash

# v3.19+ branches
# ref: https://alpinelinux.org/releases/

net_pkgs="ca-certificates curl openssl openssh-server openssh-client iproute2 net-tools nethogs wget"
tool_pkgs="bash coreutils command-not-found vim neofetch btop procps-ng lsb-release virt-what git tig unzip"
if apk info valkey >/dev/null; then
    valkey=valkey
else # backward compatibility (Alpine <=3.19)
    valkey=redis
fi
app_pkgs="monit aria2 nginx nginx-mod-http-lua nginx-mod-http-headers-more nginx-mod-http-fancyindex $valkey"

V2RAY_VERSION="5.38.0"
V2RAY_LOCATION_ASSET=${V2RAY_LOCATION_ASSET:-/etc/v2ray}
V2RAY_ZIP_URL=${V2RAY_ZIP_URL:-'https://github.com/v2fly/v2ray-core/releases/download/v%s/v2ray-linux-64.zip'}
V2RAY_CACHE_ZIP=/srv/v2ray-linux-64-v${V2RAY_VERSION}.zip

TIMEZONE=Asia/Shanghai
MYUSER=tenet # net -> ten

apk update
echo -e "\n==> 1) add net packages: $net_pkgs"
apk add $net_pkgs
echo -e "\n==> 2) add tool packages: $tool_pkgs"
apk add $tool_pkgs
echo -e "\n==> 3) add app packages: $app_pkgs"
apk add $app_pkgs

echo -e "\n==> 4) add app packages: v2ray"
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

echo -e "\n==> 5) set TZ=$TIMEZONE"
apk add tzdata
cp /usr/share/zoneinfo/${TIMEZONE} /etc/localtime
echo "${TIMEZONE}" > /etc/timezone
apk del tzdata

echo -e "\n==> 6) add user $MYUSER"
adduser -u 500 -D -S -h /srv/http -s /bin/ash \
    -G www-data -g www-data $MYUSER
addgroup $MYUSER users
passwd $MYUSER

