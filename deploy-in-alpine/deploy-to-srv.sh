#!/bin/bash

IPADDR="$1"
DOMAIN="$2"
DeployDIR="$(date +%F)-deploy-srv"

if [ -z "$IPADDR" -o -z "$DOMAIN" ];then
    cat <<EOF
usage: $0 [ip-addr] [domain-name]
EOF
    exit 1
fi

vport_init=$((RANDOM%10000+10000))
vport_troj=$((RANDOM%10000+20000))
v2raypath=$(mktemp -p download/ffmpeg-converted -t 'file=XXXXXXXX.az' -u)
ariang_ver=1.3.11

if [ -d $DeployDIR ];then
    echo "Do yourself! rm -rf $DeployDIR/"
    exit 2
fi
mkdir $DeployDIR
echo "==> copy etc files ..."
cp -r ./etc $DeployDIR/

#1. nginx
sed -i -e "s|{{domain-name}}|$DOMAIN|" -e "s|{{v2raypath}}|$v2raypath|" $DeployDIR/etc/sites-enabled/nginx-*.vhost
mkdir $DeployDIR/etc/ssl-certs

#2. aria2
mkdir -pv $DeployDIR/http/{.aria2,aria2-download,ariang}
aria2token=$(cat /proc/sys/kernel/random/uuid)
sed -i "s|{{ARIA2TOKEN}}|$aria2token|" $DeployDIR/etc/aria2.conf
mv $DeployDIR/etc/aria2.conf $DeployDIR/http/.aria2/
touch $DeployDIR/http/.aria2/aria2.session
auser=$(cat /proc/sys/kernel/random/uuid | cut -d- -f2,3)
apass=$(cat /proc/sys/kernel/random/uuid | cut -d- -f1,5)
printf "$auser:$(openssl passwd $apass)\n" > $DeployDIR/etc/http-passwd
echo -e "token: $aria2token\nuser: $auser\npasswd: $apass" > $DeployDIR/aria2-user-info
if [ ! -f ./AriaNg-$ariang_ver.zip ]; then
    wget -c https://github.com/mayswind/AriaNg/releases/download/$ariang_ver/AriaNg-$ariang_ver.zip
fi
echo "==> extract ariang files ..."
unzip -q ./AriaNg-$ariang_ver.zip -d $DeployDIR/http/ariang

#3. v2ray
echo "==> edit v2ray config ..."
uuid1=$(cat /proc/sys/kernel/random/uuid)
uuid2=$(cat /proc/sys/kernel/random/uuid)
tropass=$(cat /proc/sys/kernel/random/uuid | cut -d- -f1,3,5)
sed -e "s|{{UUID_1}}|${uuid1}|" -e "s|{{UUID_2}}|${uuid2}|" \
    -e "s|{{ip-addr}}|$IPADDR|" -e "s|{{vport_init}}|$vport_init|" \
    -e "s|{{vport_troj}}|$vport_troj|" -e "s|{{troj-password}}|$tropass|" \
    -e "s|{{domain-name}}|$DOMAIN|" -e "s|{{v2raypath}}|$v2raypath|" \
    -i $DeployDIR/etc/v2ray-{server,client}-config.json
mv $DeployDIR/etc/v2ray-client-config.json $DeployDIR/v2ray-client-config.json

# 4. log files
echo "==> log dir ..."
mkdir $DeployDIR/log
touch $DeployDIR/log/aria2.log
touch $DeployDIR/log/v2ray-{access,error}.log

# 5. scripts
echo "==> scripts ..."
mkdir $DeployDIR/scripts
install -m755 ./change_file_permission.sh -t $DeployDIR/scripts/
install -m755 ./prepare-alpine-v3.19+.sh -t $DeployDIR/scripts/

echo "==> Done."
cat <<EOF

1. Generate and put dhparam.pem server-adf.{crt,key} server-ztr.{crt,key}
   in $DeployDIR/etc/ssl-certs

2. mv $DeployDIR to /srv, then set files permission by
   change_file_permission.sh

3. Set monit control/config file by
   monit_config=/srv/etc/monitrc /etc/init.d/monit
   OR cfgfile=/srv/etc/monitrc /etc/init.d/monit

4. Some important information!
    - $DeployDIR/aria2-user-info
    - $DeployDIR/v2ray-client-config.json
EOF
