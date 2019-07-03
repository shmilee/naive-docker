v2ray and nginx
===============

generate `dhparam.pem` `server-v2ray.{crt,key}` for nginx

* login VPS

```
cd ./v2ray
bash ./deploy.sh ip-addr [port] [domain]
ls v2ray-deploy/
```

* download client config `v2ray-deploy/v2ray-client-config.json`
