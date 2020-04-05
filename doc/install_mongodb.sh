#!/bin/sh
# Reference:
# https://docs.mongodb.com/manual/tutorial/install-mongodb-on-ubuntu/

echo "About to  install gnupg"
sudo apt-get install gnupg

echo "About to retrieve and add key for mongodb"
wget -qO - https://www.mongodb.org/static/pgp/server-4.2.asc | sudo apt-key add -

echo "About to create /etc/apt/sources.list.d/mongodb-org-4.2.list"
echo "deb [ arch=amd64,arm64 ] https://repo.mongodb.org/apt/ubuntu bionic/mongodb-org/4.2 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-4.2.list

echo "About to execute apt-get update"
sudo apt-get update

echo "About to install mongodb-org"
sudo apt-get install -y mongodb-org

echo "About to start mongod service"
sudo systemctl start mongod

echo "The following service commands are available:"
echo "sudo systemctl daemon-reload"
echo "sudo systemctl status mongod"
echo "sudo systemctl enable mongod"
echo "sudo systemctl stop mongod"
echo "sudo systemctl restart mongod"

echo ""
echo "Note: the data directory is: /var/lib/mongodb/"
echo "Note: the configuration file is /etc/mongod.conf"
echo "Note: the log file is /var/log/mongodb/mongod.log "

