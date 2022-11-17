#!/bin/bash
# ref: https://docs.docker.com/engine/install/debian/
echo "==> add docker-ce"
apt-get update
apt-get install ca-certificates curl gnupg lsb-release
mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/debian/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
echo "deb [arch=amd64 signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian $(lsb_release -cs) stable" \
    | tee /etc/apt/sources.list.d/docker.list > /dev/null
apt-get update
apt-cache policy docker-ce
apt-get install docker-ce docker-ce-cli containerd.io docker-compose-plugin
systemctl status docker # should enabled
# install new kernel to FIX: vps modprobe: ERROR:
#   could not insert 'br_netfilter': Key was rejected by service
apt-get install linux-{image,headers}-5.10.0-19-amd64
echo "==> pull shmilee/naive"
docker pull shmilee/naive:${1:-221116}
docker tag shmilee/naive:${1:-221116} shmilee/naive:using
echo "==> add other pkgs"
apt-get install net-tools command-not-found \
    git unzip tig htop zsh vim python3-doc python3-pip
pip3 install --user pypinyin opencc
