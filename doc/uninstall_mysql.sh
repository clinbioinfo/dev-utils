#!/bin/bash

echo "Reference: https://blog.softhints.com/install-reinstall-uninstall-mysql-on-ubuntu-16/#uninstallmysqlserver"

echo "About to execute: sudo apt-get remove --purge mysql*"
sudo apt-get remove --purge mysql*

echo "About to execute: sudo apt-get autoremove"
sudo apt-get autoremove

echo "About to execute: sudo apt-get autoclean"
sudo apt-get autoclean
