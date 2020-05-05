#!/bin/bash

echo "Reference: https://computingforgeeks.com/how-to-install-apache-spark-on-ubuntu-debian/"

echo "About to execute: sudo apt update"
sudo apt update

echo "About to execute: sudo apt -y upgrade"
sudo apt -y upgrade

echo "About to execute: sudo apt install default-jdk"
sudo apt install default-jdk

echo "About to execute: java -version"
java -version

echo "About to execute: sudo apt update"
sudo apt update

echo "About to execute: sudo add-apt-repository ppa:webupd8team/java"
sudo add-apt-repository ppa:webupd8team/java

echo "About to execute: sudo apt update"
sudo apt update

echo "About to execute: sudo apt install oracle-java8-installer oracle-java8-set-default"
sudo apt install oracle-java8-installer oracle-java8-set-default

echo "About to execute: curl -O curl -O http://mirrors.advancedhosters.com/apache/spark/spark-2.4.5/spark-2.4.5-bin-hadoop2.7.tgz"
curl -O http://mirrors.advancedhosters.com/apache/spark/spark-2.4.5/spark-2.4.5-bin-hadoop2.7.tgz

echo "About to execute: tar zxvf spark-2.4.5-bin-hadoop2.7.tgz"
tar zxvf spark-2.4.5-bin-hadoop2.7.tgz

echo "About to execute: sudo mv spark-2.4.5-bin-hadoop2.7/ /opt/spark "
sudo mv spark-2.4.5-bin-hadoop2.7/ /opt/spark

echo "See setup_apache_spark.sh for remaining steps"
