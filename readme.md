Intro
=====

Use **N**ginx, **A**r**I**a2, **V**2ray to get data from somewher**E**. "拿衣服"

docker image
============

[mynginx](https://github.com/shmilee/web-in-docker/blob/master/dockerfiles/readme.md#build-packages) + aria2 + v2ray, also lua + json + redis

### build image

* Repository `shmilee.io` for mynginx in Dockerfile only works in my pc!

```
cd ./dockerfile/
docker build --force-rm --no-cache --rm -t shmilee/naive:$(date +%y%m%d) .
docker tag shmilee/naive:$(date +%y%m%d) shmilee/naive:using
docker push shmilee/naive:$(date +%y%m%d)
```

deploy nginx, aria2 and v2ray
=============================

### clone repo

```
git clone https://github.com/shmilee/naive-docker.git
cd naive-docker/
```

### pre docker in vps

example in debian 9, run as root

```
bash ./pre-docker-debian9.sh
```

### deploy

```
bash ./deploy.sh ip-addr [domain]
ls "$(date +%F)-deploy"
# copy some old deploy-files to new deploy-dir/ if needed
bash ./deploy-post-cp2new.sh [src] [dst]
```

* Note: [SSL certificates, Cloudflare SSL options](https://developers.cloudflare.com/ssl/origin-configuration/ssl-modes)
  - no certificate, Off & Flexible **not recommended**
  - self-signed, Full
  - valid & trusted by Cloudflare, Full (strict)

* Note: [Cloudflare worker routes for jsproxy](https://developers.cloudflare.com/workers/platform/routing/routes)
  - DNS record, `xxxx`
  - add route, `xxxx.yyy.zz/*`

* download
  - aria2 token, user, passwd `20XX-XX-XX-deploydir/aria2-user-info`
  - v2ray client config `20XX-XX-XX-deploy/v2ray-client-config.json`
  - jsproxy url, user, passwd `20XX-XX-XX-deploy/jsproxy-info`

### optional optimization

* `turn-on-tcp_bbr.sh`
* `turn-on-tcp_fastopen.sh`

### optional ipv6 for google

* `HE ipv6 tunnel` script to `/etc/rc.local`
* `etc-docker-daemon.json`:
  ```
  {
    "ipv6": true,
    "fixed-cidr-v6": "Tunnel_detail, Routed IPv6 Prefixes, 2001:470:x:y::/64"
  }  
  ```
