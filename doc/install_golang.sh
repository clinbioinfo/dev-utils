#!/bin/sh
echo "About to install golang"
sudo add-apt-repository ppa:longsleep/golang-backports
sudo apt update
sudo apt install golang-go
echo "Reference: https://github.com/golang/go/wiki/Ubuntu"
