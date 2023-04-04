#!/usr/bin/bash
echo "Will attempt to install python 3.11"
sudo add-apt-repository ppa:deadsnakes/ppa
sudo apt update
sudo apt install python3.11
