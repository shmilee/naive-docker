#!/bin/bash
# ref: https://wiki.archlinux.org/index.php/Shadowsocks_(简体中文)#性能优化
modprobe tcp_bbr
echo "tcp_bbr" > /etc/modules-load.d/tcp-bbr.conf
echo '
net.core.default_qdisc=fq
net.ipv4.tcp_congestion_control=bbr
' > /etc/sysctl.d/tcp-bbr.conf
sysctl -p /etc/sysctl.d/tcp-bbr.conf
