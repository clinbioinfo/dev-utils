#!/bin/sh
echo "Will attempt to install PostgreSQL"
sudo sh -c 'echo "deb http://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list'
wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add -
sudo apt-get update
sudo apt-get -y install postgresql
echo "Reference https://www.postgresql.org/download/linux/ubuntu/"


echo "Connect to PostgreSQL and set the password for the postgres account by executing the following:"
echo "sudo su - postgres"
echo "psql"
echo "ALTER USER postgres WITH PASSWORD 'postgres';"

