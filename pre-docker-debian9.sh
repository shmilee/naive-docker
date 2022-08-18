#!/bin/bash
# ref: https://www.digitalocean.com/community/tutorials/how-to-install-and-use-docker-on-debian-9
echo "==> add docker-ce"
apt-get update
apt-get install apt-transport-https ca-certificates curl gnupg2 software-properties-common
curl -fsSL https://download.docker.com/linux/debian/gpg | apt-key add -
add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/debian $(lsb_release -cs) stable"
apt-get update
apt-cache policy docker-ce
apt-get install docker-ce
systemctl status docker # should enabled
echo "==> pull shmilee/naive"
docker pull shmilee/naive:${1:-190728}
docker tag shmilee/naive:${1:-190728} shmilee/naive:using
echo "==> add other pkgs"
apt-get install unzip tig htop zsh vim python3-doc python3-pip
pip3 install --user pypinyin opencc
