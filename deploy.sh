#!/bin/bash

ipaddr=${1}
domain=${2:-$ipaddr}

if [ -z $ipaddr ];then
    cat <<EOF
usage: $0 ip-addr [domain]
default domain is ip-addr
EOF
    exit 1
fi

port=$RANDOM
v2raypath=$(mktemp -p download/huge -t 'dataid=XXXXXXXXXX' -u)
deploydir="$(date +%F)-deploy"
ariang_ver=1.1.1

if [ -d $deploydir ];then
    echo "Do yourself! sudo rm -rf $deploydir/"
    exit 2
fi
mkdir $deploydir
echo "==> copy etc files ..."
cp -r etc $deploydir/

#1. nginx
sed -i -e "s|{{domain-name}}|$domain|" -e "s|{{v2raypath}}|$v2raypath|" $deploydir/etc/sites-enabled/nginx-*.vhost

#2. aria2
mkdir -pv $deploydir/http/{.aria2,aria2-download,ariang}
aria2token=$(cat /proc/sys/kernel/random/uuid)
sed -i "s|{{ARIA2TOKEN}}|$aria2token|" $deploydir/etc/aria2.conf
mv $deploydir/etc/aria2.conf $deploydir/http/.aria2/
touch $deploydir/http/.aria2/aria2.session
auser=$(cat /proc/sys/kernel/random/uuid | cut -d- -f2,3)
apass=$(cat /proc/sys/kernel/random/uuid | cut -d- -f1,5)
printf "$auser:$(openssl passwd -crypt $apass)\n" > $deploydir/etc/http-passwd
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
sed -e "s|{{UUID1}}|${uuid1}|" -e "s|{{UUID2}}|${uuid2}|" \
    -e "s|{{port1}}|$port|" \
    -e "s|{{v2raypath}}|$v2raypath|" \
    -i $deploydir/etc/v2ray-server-config.json
sed -e "s|{{UUID1}}|${uuid1}|" -e "s|{{UUID2}}|${uuid2}|" \
    -e "s|{{ip-addr}}|$ipaddr|" -e "s|{{port1}}|$port|" \
    -e "s|{{domain-name}}|$domain|" -e "s|{{v2raypath}}|$v2raypath|" \
    -i $deploydir/etc/v2ray-client-config.json
mv $deploydir/etc/v2ray-client-config.json $deploydir/v2ray-client-config.json

echo "==> gen $deploydir/{test.sh,run.sh}"
cat <<'EOF' | sed "s|{{port1}}|$port|g" > $deploydir/test.sh
#!/bin/bash
#    -v /usr/share/doc/python/html:/usr/share/doc/python3/html \
docker run --rm --name naive \
    -p 80:80 -p 443:443 -p {{port1}}:{{port1}} \
    -v $PWD:/srv:rw \
    shmilee/naive:${1:-using}
EOF
sed 's|--rm|--detach --restart=always|'  $deploydir/test.sh > $deploydir/run.sh
chmod +x $deploydir/{test.sh,run.sh}

echo "==> log dir ..."
mkdir $deploydir/log

echo "==> Done."
cat <<EOF

Generate and put dhparam.pem server-{ariang,v2ray,www}.{crt,key} in $deploydir/etc/ssl-certs
Run test
    cd  $deploydir/
    ./test.sh [naive-image-tag]
If containers run scucessfully, then
    ./run.sh [naive-image-tag]
Some important information!
    $deploydir/aria2-user-info
    $deploydir/v2ray-client-config.json
EOF
