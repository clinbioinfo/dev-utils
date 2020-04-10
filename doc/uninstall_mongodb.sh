#!/bin/sh
# Reference:
# https://docs.mongodb.com/manual/tutorial/install-mongodb-on-ubuntu/

echo "About to uninstall mongodb"

echo "About to execute: sudo apt-get purge mongodb-org*"
sudo apt-get purge mongodb-org*

echo "About to execute: sudo rm -r /var/log/mongodb"
sudo rm -r /var/log/mongodb

echo "About to execute: sudo rm -r /var/lib/mongodb"
sudo rm -r /var/lib/mongodb
