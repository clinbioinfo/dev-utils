#!/bin/sh
echo "About to install golang"
sudo add-apt-repository ppa:longsleep/golang-backports
sudo apt update
sudo apt install golang-go
echo "Reference: https://github.com/golang/go/wiki/Ubuntu"

echo "Adding GOPATH to environment"
export GOPATH="/home/jsundaram/go"
export PATH=$PATH:$GOPATH/bin

echo "Adding GOPATH to ~/.zshrc"
echo "export GOPATH=\"/home/jsundaram/go\"" >> ~/.zshrc
echo "export PATH=$PATH:$GOPATH/bin" >> ~/.zshrc
 
