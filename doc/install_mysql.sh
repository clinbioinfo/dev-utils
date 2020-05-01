#!/bin/bash
echo "About to execute: sudo apt update"
sudo apt update

echo "About to execute: sudo apt install mysql-server"
sudo apt install mysql-server

echo "About to execute: sudo mysql_secure_installation"
sudo mysql_secure_installation

echo "Reference: https://www.digitalocean.com/community/tutorials/how-to-install-mysql-on-ubuntu-18-04"
echo "To check status, execute: sudo service mysql status"
echo "To start the service, execute: sudo service mysql start"
echo "To stop the service, execute: sudo service mysql stop"
echo "Connect like this: mysql -u root -p"
