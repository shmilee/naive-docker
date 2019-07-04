Intro
=====

Use **n**ginx, **a**r**i**a2, **v**2ray to get data from somewher**e**. "拿衣服"

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
```

* download v2ray client config `20XX-XX-XX-deploy/etc/v2ray-client-config.json`
