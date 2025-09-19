#!/bin/bash

chown -R root:root /srv/
chmod 600 /srv/etc/monitrc

chown -R 500:www-data /srv/http/{.aria2,aria2-download,ariang}
chown 500:www-data /srv/log/aria2.log

chown nobody:nobody /srv/log/v2ray-access.log
chown nobody:nobody /srv/log/v2ray-error.log
for file in server-ztr.key server-ztr.crt; do
    if [ -f "/srv/etc/ssl-certs/$file" ]; then
        chown nobody:nobody /srv/etc/ssl-certs/$file
    fi
done
