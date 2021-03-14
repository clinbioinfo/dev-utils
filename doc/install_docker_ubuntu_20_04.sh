#!/bin/sh

echo "Will attempt to execute: sudo apt update"
sudo apt update

echo "Will attempt to execute: sudo apt install apt-transport-https ca-certificates curl software-properties-common"
sudo apt install apt-transport-https ca-certificates curl software-properties-common

echo "Will attempt to execute: curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -"
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -

echo "Will attempt to execute: sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu focal stable""
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu focal stable"

echo "Will attempt to execute: sudo apt update"
sudo apt update

echo "Will attempt to execute: apt-cache policy docker-ce"
apt-cache policy docker-ce

echo "Will attempt to execute: sudo apt install docker-ce"
sudo apt install docker-ce

echo "Will attempt to execute: sudo systemctl status docker"
sudo systemctl status docker

echo "Will attempt to execute: sudo usermod -aG docker ${USER}"
sudo usermod -aG docker ${USER}

echo "Will attempt to execute: su - ${USER}"
su - ${USER}

echo "Will attempt to execute: sudo usermod -aG docker ${USER}"
sudo usermod -aG docker ${USER}


Reference: https://www.digitalocean.com/community/tutorials/how-to-install-and-use-docker-on-ubuntu-20-04
