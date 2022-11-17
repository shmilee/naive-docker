#!/bin/bash
# ref: https://docs.docker.com/engine/install/debian/
echo "==> add docker-ce"
apt-get update
apt-get install ca-certificates curl gnupg lsb-release
curl -fsSL https://download.docker.com/linux/debian/gpg | apt-key add -
add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/debian $(lsb_release -cs) stable"
echo "deb [arch=amd64] https://download.docker.com/linux/debian $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null

apt-get update
apt-cache policy docker-ce
apt-get install docker-ce
systemctl status docker # should enabled
echo "==> pull shmilee/naive"
docker pull shmilee/naive:${1:-221116}
docker tag shmilee/naive:${1:-221116} shmilee/naive:using
echo "==> add other pkgs"
apt-get install unzip tig htop zsh vim python3-doc python3-pip
pip3 install --user pypinyin opencc
