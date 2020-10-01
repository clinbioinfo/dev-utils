#!/bin/sh
echo "Will attempt to install Java Runtime Environment (JRE) from JDK"
sudo apt update
sudo apt install -y default-jre
sudo apt install -y default-jdk
echo "java -version:"
java -version
echo "javac -version"
javac -version
echo "Reference: https://www.digitalocean.com/community/tutorials/how-to-install-java-with-apt-on-ubuntu-20-04"

