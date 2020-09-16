#!/bin/sh

echo "Will attempt to download the zip file"
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"

echo "Will attempt to unzip the zip file awscliv2.zip"
unzip awscliv2.zip

echo "Will attempt to install the awscliv2 software"
sudo ./aws/install

echo "Reference: https://docs.aws.amazon.com/cli/latest/userguide/install-cliv2-linux.html"
