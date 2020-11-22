#!/bin/sh
echo "Will attempt to install python 3.9.0"
sudo add-apt-repository ppa:deadsnakes/ppa
sudo apt update
sudo apt install -y python3.9
echo "Reference http://ubuntuhandbook.org/index.php/2020/10/python-3-9-0-released-install-ppa-ubuntu/"
