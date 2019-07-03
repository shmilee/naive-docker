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

generate `dhparam.pem` `server-{ariang,v2ray,www}.{crt,key}` for nginx

```
bash ./deploy.sh ip-addr [domain]
ls deploy/
```

* download v2ray client config `deploy/v2ray-client-config.json`
