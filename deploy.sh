#!/bin/bash

ipaddr=${1}
domain=${2:-$ipaddr}
dynamicport=off
mkcp=off

if [ -z $ipaddr ];then
    cat <<EOF
usage: $0 ip-addr [domain]
default domain is ip-addr, should use 'only one domain' config
EOF
    exit 1
fi

vport_init=$((RANDOM%5000+5000))
vport_dmin=$((RANDOM%1000+10000))
vport_dmax=$((RANDOM%1000+12000))
vport_troj=$((vport_init+50))
v2raypath=$(mktemp -p download/huge -t 'dataid=XXXXXXXXXX' -u)
deploydir="$(date +%F)-deploy"
ariang_ver=1.3.7
headscale_ui_ver='2024.10.05'
jsproxy_ver=0.1.0

if [ -d $deploydir ];then
    echo "Do yourself! sudo rm -rf $deploydir/"
    exit 2
fi
mkdir $deploydir
echo "==> copy etc files ..."
cp -r etc $deploydir/

#1. nginx
sed -i -e "s|{{domain-name}}|$domain|" -e "s|{{v2raypath}}|$v2raypath|" $deploydir/etc/sites-enabled/nginx-*.vhost
# AUR repo
mkdir -pv  $deploydir/repo-shmilee

#2. aria2
mkdir -pv $deploydir/http/{.aria2,aria2-download,ariang}
aria2token=$(cat /proc/sys/kernel/random/uuid)
sed -i "s|{{ARIA2TOKEN}}|$aria2token|" $deploydir/etc/aria2.conf
mv $deploydir/etc/aria2.conf $deploydir/http/.aria2/
touch $deploydir/http/.aria2/aria2.session
auser=$(cat /proc/sys/kernel/random/uuid | cut -d- -f2,3)
apass=$(cat /proc/sys/kernel/random/uuid | cut -d- -f1,5)
printf "$auser:$(openssl passwd $apass)\n" > $deploydir/etc/http-passwd
echo -e "token: $aria2token\nuser: $auser\npasswd: $apass" > $deploydir/aria2-user-info
if [ ! -f AriaNg-$ariang_ver.zip ]; then
    wget -c https://github.com/mayswind/AriaNg/releases/download/$ariang_ver/AriaNg-$ariang_ver.zip
fi
echo "==> extract ariang files ..."
unzip -q ./AriaNg-$ariang_ver.zip -d $deploydir/http/ariang

#3. v2ray
echo "==> edit v2ray config ..."
uuid1=$(cat /proc/sys/kernel/random/uuid)
uuid2=$(cat /proc/sys/kernel/random/uuid)
tropass=$(cat /proc/sys/kernel/random/uuid | cut -d- -f1,3,5)
sed -e "s|{{UUID_1}}|${uuid1}|" -e "s|{{UUID_2}}|${uuid2}|" \
    -e "s|{{ip-addr}}|$ipaddr|" -e "s|{{vport_init}}|$vport_init|" \
    -e "s|{{vport_dmin}}|$vport_dmin|" -e "s|{{vport_dmax}}|$vport_dmax|" \
    -e "s|{{vport_troj}}|$vport_troj|" -e "s|{{troj-password}}|$tropass|" \
    -e "s|{{domain-name}}|$domain|" -e "s|{{v2raypath}}|$v2raypath|" \
    -i $deploydir/etc/v2ray-{server,client}-config.json
if [[ $dynamicport == 'on' ]]; then
    sed -e 's|//dyp-||' -i $deploydir/etc/v2ray-{server,client}-config.json
fi
if [[ $mkcp == 'on' ]]; then
    sed -e 's|//mkcp-||' -i $deploydir/etc/v2ray-{server,client}-config.json
fi
mv $deploydir/etc/v2ray-client-config.json $deploydir/v2ray-client-config.json

#4. headscale
mkdir -v $deploydir/headscale
# Get new etc/headscale-config.yaml:
# > wget -O ./etc/headscale-config.yaml https://github.com/juanfont/headscale/raw/v?.???/config-example.yaml
# edit path, url:
# > sed -i -e 's|/var/lib/headscale/|/srv/headscale/|' -e 's|/var/run/|/srv/headscale/|' ./etc/headscale-config.yaml
# > sed -i 's|server_url: http://127.0.0.1:8080|server_url: https://headscale.{{domain-name}}|' ./etc/headscale-config.yaml
# about ip_prefixes: IPv4 172.18.18.0/24
# > sed -i '/ip_prefixes/{
# > N
# > N
# > s|\(.*\n\)\(.*/48\)\n\(.*\) 100\.64.*|\1\3 172.18.18.0/24\n\2|
# > }' ./etc/headscale-config.yaml 
sed -i -e "s|{{domain-name}}|$domain|" $deploydir/etc/headscale-config.yaml
if [ ! -f headscale-ui-$headscale_ui_ver.zip ]; then
    wget -O headscale-ui-$headscale_ui_ver.zip -c https://github.com/gurucomputing/headscale-ui/releases/download/$headscale_ui_ver/headscale-ui.zip
fi
echo "==> extract headscale-ui files ..."
unzip -q ./headscale-ui-$headscale_ui_ver.zip -d $deploydir/http/headscale-ui

#5. article
echo "==> add article files ..."
cp -r article $deploydir/http/
old_PATH="$(pwd)"
cd $deploydir/http/article/mryw/
python3 ./meiriyiwen.py
rm -rf ./split-jsons/
cd "${old_PATH}"

#6. jsproxy
echo "==> download jsproxy files ..."
cd $deploydir/etc/jsproxy
./download.sh $jsproxy_ver
cd "${old_PATH}"
jwho=$(cat /proc/sys/kernel/random/uuid | cut -d- -f4)
jkey=$(cat /proc/sys/kernel/random/uuid | cut -d- -f5)
printf "$jwho:$(openssl passwd $jkey)\n" > $deploydir/etc/http-passwd-jsproxy
pass64=$(echo -n "$jwho:$jkey" | base64) # js btoa("$jwho:$jkey")
sed -e "s|ASSET_URL = '.*etherdream.github.io.*'|ASSET_URL = 'https://jsproxy.$domain'|" \
    -e "s|fetch(ASSET_URL + path)|fetch(ASSET_URL + path, {headers:{'Authorization': 'Basic $pass64'}})|" \
    $deploydir/etc/jsproxy/jsproxy-$jsproxy_ver/cf-worker/index.js \
    > $deploydir/jsproxy-cf-worker-index.js
echo -e "url: https://jsproxy.$domain\nuser: $jwho\npasswd: $jkey\ncf-worker-js: jsproxy-cf-worker-index.js" > $deploydir/jsproxy-info

# x. only one domain
sed -i -e "s|{{domain-name}}|$domain|" -e "s|{{v2raypath}}|$v2raypath|" \
    $deploydir/etc/sites-disabled/nginx-one.vhost
sed -e "s|v2ray.$domain|$domain|" $deploydir/v2ray-client-config.json \
    > $deploydir/v2ray-client-one-domain-config.json

echo "==> gen $deploydir/{test.sh,run.sh}"
cat > $deploydir/test.sh <<'EOF'
#!/bin/bash
docker run --rm --name naive {{network-opt}} \
    -v /usr/share/doc/python3/html:/usr/share/doc/python3/html \
    -v $PWD:/srv:rw shmilee/naive:${1:-using}
EOF
if [[ $dynamicport == 'on' || $mkcp == 'on' ]]; then
    sed -e "s|{{network-opt}}|--network=host|" -i $deploydir/test.sh
else
    more_ports="-p $vport_init:$vport_init -p $vport_troj:$vport_troj"
    sed -e "s|{{network-opt}}|-p 80:80 -p 443:443 $more_ports|" -i $deploydir/test.sh
fi
sed 's|--rm|--detach --restart=always|'  $deploydir/test.sh > $deploydir/run.sh
chmod +x $deploydir/{test.sh,run.sh}

echo "==> log dir ..."
mkdir $deploydir/log

echo "==> Done."
cat <<EOF

Generate and put dhparam.pem server-{www-ariang-jsproxy,v2fly}.{crt,key} in $deploydir/etc/ssl-certs
Run test
    cd  $deploydir/
    ./test.sh [naive-image-tag]
If containers run scucessfully, then
    ./run.sh [naive-image-tag]
Some important information!
    $deploydir/aria2-user-info
    $deploydir/v2ray-client-config.json
    $deploydir/jsproxy-info
EOF
