#!/bin/sh
echo "Will attempt to execute 'sudo apt update'"
sudo apt update
echo "Will attempt to install nodejs"
sudo apt install -y nodejs
echo "This version has been installed:"
nodejs -v
echo "Will attempt to install npm"
sudo apt install -y npm
echo "Reference: https://www.digitalocean.com/community/tutorials/how-to-install-node-js-on-ubuntu-20-04"
