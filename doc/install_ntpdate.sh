#!/bin/sh
echo "Will attempt to install ntp and ntpdate"
sudo apt-get install ntp
sudo apt-get install ntpdate
sudo ntpdate ntp.ubuntu.com

echo "Reference: https://askubuntu.com/questions/214246/how-to-fix-wrong-system-time-and-date"

