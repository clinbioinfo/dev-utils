#!/bin/sh
echo "Going to install zsh"
sudo apt-get -y install zsh

echo "Going to install curl"
sudo apt-get install -y curl

echo "Going to install oh-my-zsh"
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
