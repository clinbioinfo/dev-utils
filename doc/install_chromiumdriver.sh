#!/bin/sh
echo "About to install chromedriver"
cd ${HOME}

echo "About to execute: sudo apt-get update"
sudo apt-get update

echo "About to execute: sudo apt-get install -y unzip xvfb libxi6 libgconf-2-4"
sudo apt-get install -y unzip xvfb libxi6 libgconf-2-4

echo "About to execute: sudo apt-get install default-jdk"
sudo apt-get install default-jdk

echo "About to execute: get https://chromedriver.storage.googleapis.com/2.41/chromedriver_linux64.zip"
wget https://chromedriver.storage.googleapis.com/2.41/chromedriver_linux64.zip

echo "About to execute: unzip chromedriver_linux64.zip"
unzip chromedriver_linux64.zip

echo "About to execute: sudo mv chromedriver /usr/bin/chromedriver"
sudo mv chromedriver /usr/bin/chromedriver

echo "About to execute: sudo chown root:root /usr/bin/chromedriver"
sudo chown root:root /usr/bin/chromedriver

echo "About to execute: sudo chmod +x /usr/bin/chromedriver"
sudo chmod +x /usr/bin/chromedriver

echo "About to execute: wget https://selenium-release.storage.googleapis.com/3.13/selenium-server-standalone-3.13.0.jar"
wget https://selenium-release.storage.googleapis.com/3.13/selenium-server-standalone-3.13.0.jar

echo "About to execute: wget http://www.java2s.com/Code/JarDownload/testng/testng-6.8.7.jar.zip"
wget http://www.java2s.com/Code/JarDownload/testng/testng-6.8.7.jar.zip

echo "About to execute: unzip testng-6.8.7.jar.zip"
unzip testng-6.8.7.jar.zip

echo "Execute the follwoing to run chromedriver:"
echo "xvfb-run java -Dwebdriver.chrome.driver=/usr/bin/chromedriver -jar selenium-server-standalone-3.13.0.jar"

echo "Reference: https://tecadmin.net/setup-selenium-chromedriver-on-ubuntu/"

