Intro
=====

Use **N**ginx, **A**r**I**a2, **V**2ray, h**E**adscale to get data from somewhere. "拿衣服"

docker image
============

[mynginx](https://github.com/shmilee/web-in-docker/blob/master/dockerfiles/readme.md#build-packages) + aria2 + v2ray + headscale, also lua + json + redis

### build image

* Repository `shmilee.io` for mynginx in Dockerfile only works in my pc!

```bash
cd ./dockerfile/
docker build --force-rm --no-cache --rm -t shmilee/naive:$(date +%y%m%d) .
docker tag shmilee/naive:$(date +%y%m%d) shmilee/naive:using
docker push shmilee/naive:$(date +%y%m%d)
```

deploy naive
=============

### prepare docker, image, packages, clone repo etc.

example in debian 11+, run as root

```bash
bash <(curl -Lso- https://github.com/shmilee/naive-docker/raw/master/prepare-debian11+.sh)
```

* Note: install new kernel to FIX `vps modprobe: ERROR` in debian 11.
    could not insert 'br_netfilter': Key was rejected by service
  - `apt-get update && apt-get install linux-image-5.10.0-19-amd64`
  - reboot

### deploy

```bash
cd naive-docker/
bash ./deploy.sh ip-addr [domain]
ls "$(date +%F)-deploy"
# copy some old deploy-files to new deploy-dir/ if needed
bash ./deploy-post-cp2new.sh [src] [dst]
```

* Note: [SSL certificates, Cloudflare SSL options](https://developers.cloudflare.com/ssl/origin-configuration/ssl-modes)
  - no certificate, Off & Flexible **not recommended**
  - self-signed, Full
  - valid & trusted by Cloudflare, Full (strict)

```bash
# web-in-docker/other_tools/gen-CA-crt/gen-crt.sh
gen-crt.sh server domainxxx-whatyyy
# about SAN subjectAltName: `DNS:what1.domainxxx,DNS:what2.domainxxx
# about Common Name: `whatall.domainxxx`
```

* Note: [Cloudflare worker routes for jsproxy](https://developers.cloudflare.com/workers/platform/routing/routes)
  - DNS record, `xxxx`
  - add route, `xxxx.yyy.zz/*`

* headscale
    - `docker exec naive headscale -c /srv/etc/headscale-config.yaml apikeys create`

* ChatGPT web
    - deploy by docker image
    - modify the corresponding ip:port in `$(date +%F)-deploy/etc/sites-enabled/nginx-chat.vhost`

* download
  - aria2 token, user, passwd `20XX-XX-XX-deploydir/aria2-user-info`
  - v2ray client config `20XX-XX-XX-deploy/v2ray-client-config.json`
  - jsproxy url, user, passwd `20XX-XX-XX-deploy/jsproxy-info`

### optional optimization

* `turn-on-tcp_bbr.sh`
* `turn-on-tcp_fastopen.sh`

### optional ipv6 tunnel for google

* `HE ipv6 tunnel` script to `/etc/rc.local`
* `etc-docker-daemon.json`:
  ```json
  {
    "ipv6": true,
    "fixed-cidr-v6": "Tunnel_detail, Routed IPv6 Prefixes, 2001:470:x:y::/64"
  }  
  ```

### optional WARP ipv4, ipv6 for google scholar

* repo: https://gitlab.com/fscarmen/warp

* install

```bash
wget -N https://gitlab.com/fscarmen/warp/-/raw/main/menu.sh && bash menu.sh d
```

* Working mode: Global
    - https://gitlab.com/fscarmen/warp/-/issues/3
    - add `docker run --network=host` in `test.sh`, `run.sh`
