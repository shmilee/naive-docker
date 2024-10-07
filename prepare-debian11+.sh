#!/bin/bash

# ref: https://docs.docker.com/engine/install/debian/
echo -e "\n==> 1) add docker-ce"
apt-get update
apt-get install ca-certificates curl gnupg lsb-release
mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/debian/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
echo "deb [arch=amd64 signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian $(lsb_release -cs) stable" \
    | tee /etc/apt/sources.list.d/docker.list > /dev/null
apt-get update
apt-cache policy docker-ce
apt-get install docker-ce docker-ce-cli containerd.io docker-compose-plugin
systemctl --no-pager --full status docker  # should enabled

echo -e "\n==> 2) pull shmilee/naive"
docker pull shmilee/naive:${1:-241008}
docker tag shmilee/naive:${1:-241008} shmilee/naive:using

echo -e "\n==> 3) add some packages"
apt-get install openssh-server net-tools nethogs command-not-found \
    tzdata screen htop zsh unzip vim w3m wget \
    git tig python3-doc python3-pip
export PIP_BREAK_SYSTEM_PACKAGES=1
pip3 install --user pypinyin opencc
pip3 install --user git+https://github.com/shmilee/gdpy3.git

echo -e "\n==> 4) set TZ='Asia/Shanghai'"
timedatectl set-timezone Asia/Shanghai  # or tzselect
timedatectl status

echo -e "\n==> X) clone naive git repo"
git clone https://github.com/shmilee/naive-docker.git
