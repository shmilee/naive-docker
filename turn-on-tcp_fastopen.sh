#!/bin/bash
echo 'net.ipv4.tcp_fastopen = 3' > /etc/sysctl.d/tcp-fastopen.conf
sysctl -p /etc/sysctl.d/tcp-fastopen.conf
