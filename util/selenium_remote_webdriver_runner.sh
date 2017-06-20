#!/bin/sh

chromedriver="/usr/local/bin/chromedriver"

jarfile="/usr/local/bin/selenium-server-standalone-3.0.1.jar"

if [ ! -e ${chromedriver} ]
then
	echo "'${chromedriver}' does not exist"
	exit 1
fi

if [ ! -e ${jarfile} ]
then
	echo "'${jarfile}' does not exist"
	exit 1
fi

xvfb-run java -Dwebdriver.chrome.driver=${chromedriver} -jar ${jarfile} -debug