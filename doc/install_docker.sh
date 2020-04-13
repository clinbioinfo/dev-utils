#!/bin/sh
echo "About to install docker"
echo "Reference: https://phoenixnap.com/kb/how-to-install-docker-on-ubuntu-18-04"

echo "About to execute: sudo apt-get update"
sudo apt-get update

echo "About to execute: sudo apt-get remove docker docker-engine docker.io"
sudo apt-get remove docker docker-engine docker.io

echo "About to execute: sudo apt install -y docker.io"
sudo apt install -y docker.io

echo "About to execute: start docker daemon"
sudo systemctl start docker

echo "About to execute: sudo systemctl enable docker"
sudo systemctl enable docker

echo "About to execute: docker --version"
docker --version



