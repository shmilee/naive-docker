# Use monit to manage mynginx + headscale + aria2 + v2ray + headscale + lua json + redis processes
#
# docker build --force-rm --no-cache --rm -t shmilee/naive:$(date +%y%m%d) .
#

FROM alpine:3.16

LABEL maintainer="shmilee <shmilee.zju@gmail.com>" version="1.0"

ENV LANG=en_US.UTF-8 LC_ALL=en_US.UTF-8 \
    TIMEZONE=Asia/Shanghai \
    TERM=xterm-color

# Add my repository
COPY ./*@*.rsa.pub /etc/apk/keys/
RUN echo http://shmilee.io/repo-shmilee/alpine-v3.16/shmilee > /etc/apk/repositories

RUN echo https://mirrors.tuna.tsinghua.edu.cn/alpine/v3.16/main >> /etc/apk/repositories \
 && echo https://mirrors.tuna.tsinghua.edu.cn/alpine/v3.16/community >> /etc/apk/repositories \
 && adduser -u 82 -D -S -h /srv/http -G www-data -g www-data www-data \
 && echo "==> tini monit mynginx aria2 cjson redis..." \
 && apk --no-cache add coreutils bash nano tzdata ca-certificates openssl \
        tini monit iproute2 \
        mynginx mynginx-meta-small-modules \
        aria2 lua5.1-cjson redis\
 && cp /usr/share/zoneinfo/${TIMEZONE} /etc/localtime \
 && echo "${TIMEZONE}" > /etc/timezone

COPY ./monit_init.sh ./install_v2ray.sh ./install_headscale.sh /usr/bin/
RUN echo "==> monit_init install_v2ray install_headscale ..." \
 && chmod +x /usr/bin/monit_init.sh /usr/bin/install_v2ray.sh /usr/bin/install_headscale.sh \
 && mkdir -p /etc/v2ray /etc/headscale /var/lib/headscale \
 && adduser -u 532 -D -S -h /srv/headscale -s /usr/bin/nologin -G www-data -g www-data headscale \
 && chown headscale:www-data /var/lib/headscale

ENTRYPOINT ["/sbin/tini", "--"]
CMD ["monit_init.sh", "5"]
