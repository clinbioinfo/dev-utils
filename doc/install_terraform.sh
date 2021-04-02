#!/bin/sh
echo "Will attempt to install Terraform"
echo "Will attempt to execute: curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo apt-key add -"
curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo apt-key add -

echo "Will attempt to execute: sudo apt-add-repository 'deb [arch=$(dpkg --print-architecture)] https://apt.releases.hashicorp.com $(lsb_release -cs) main'"
sudo apt-add-repository "deb [arch=$(dpkg --print-architecture)] https://apt.releases.hashicorp.com $(lsb_release -cs) main"

echo "Will attempt to execute: sudo apt install -y terraform"
sudo apt install -y terraform

echo "Reference: https://www.terraform.io/docs/cli/install/apt.html"

