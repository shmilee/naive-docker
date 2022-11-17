#!/bin/bash
# Copyright (C) 2022 shmilee
src="${1}"
dst="${2:-$(date +%F)-deploy}"
if [ x"$src" == x"" ]; then
    echo "usage: $0 <src> <dst>"
    exit 1
fi
cp_files() {  # ${src}/xx/yy/zz*.zip -> ${dst}/xx/yy/
    path="$1"    # xx/yy/ or ""
    prefix="${2:-""}"  # zz or ""
    suffix="${3:-""}"  # .zip or ""
    for file in `ls -d "${src}/${path}${prefix}"*${suffix} 2>/dev/null`; do
        cp -r -v -p "$file" "${dst}/${path}"
    done
}
echo ' ==> backup logs'
cp_files "" 'backup-log-' '.tar.gz'
echo ' ==> v2ray zip'
cp_files "" 'v2ray-linux-64-v' '.zip'
echo ' ==> headscale bin'
cp_files "" 'headscale_' '_linux_amd64'
echo ' ==> http-passwd'
tail -n1 "$src"/etc/http-passwd >> "$dst"/etc/http-passwd
tail -n1 "$src"/etc/http-passwd-jsproxy >> "$dst"/etc/http-passwd-jsproxy
echo ' ==> ssl-certs'
cp_files 'etc/ssl-certs/'
echo ' ==> aria2 download files'
cp_files "http/aria2-download/"
echo ' ==> x2zl jsons'
path='http/article/x2zl/jsons'
[ -d "$dst"/$path ] || mkdir -pv "$dst"/$path
cp_files "$path/"
