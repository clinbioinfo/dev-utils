#!/bin/sh
# Reference:
# https://www.programsbuzz.com/article/install-robomongo-robo-3t-ubuntu-1804
echo "About to install Robo 3T"

echo "About to execute: sudo apt install libcanberra-gtk0 libcanberra-gtk-module"
sudo apt install libcanberra-gtk0 libcanberra-gtk-module

DOWNLOAD_FILE=${HOME}/Downloads/studio-3t-linux-x64.tar.gz
if [! -f ${DOWNLOAD_FILE} ]; then
  echo "Please download the Robo 3T file from https://studio3t.com/download/ and then rename it studio-3t-linux-x64.tar.gz"
  exit 1
fi

echo "About to execute: sudo mkdir -p /usr/local/bin/robomongo"
sudo mkdir -p /usr/local/bin/robomongo

echo "About to execute: sudo mv ~/Downloads/studio-3t-linux-x64.tar.gz /usr/local/bin/robomongo/."
sudo mv ~/Downloads/studio-3t-linux-x64.tar.gz /usr/local/bin/robomongo/.

echo "About to execute: cd /usr/local/bin/robomonogo"
cd /usr/local/bin/robomonogo

echo "About to execute: sudo tar -xvzf studio-3t-linux-x64.tar.gz"
sudo tar -xvzf studio-3t-linux-x64.tar.gz

echo "About to execute ./studio-3t-linux-x64.sh"
./studio-3t-linux-x64.sh
