#!/bin/sh
echo "About to install docker-compose"
echo "Reference: https://www.digitalocean.com/community/tutorials/how-to-install-docker-compose-on-ubuntu-18-04"

VERSION=1.28.5

echo "About to execute: sudo curl -L https://github.com/docker/compose/releases/download/${VERSION}/docker-compose-`uname -s`-`uname -m` -o /usr/local/bin/docker-compose"
sudo curl -L https://github.com/docker/compose/releases/download/${VERSION}/docker-compose-`uname -s`-`uname -m` -o /usr/local/bin/docker-compose

echo "About to execute: sudo chmod +x /usr/local/bin/docker-compose"
sudo chmod +x /usr/local/bin/docker-compose

echo "About to execute: docker-compose --version"
docker-compose --version


