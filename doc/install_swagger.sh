#!/bin/sh
sh $HOME/dev-utils/doc/install_swagger.sh
echo "Will attempt to install swagger"
npm install -g http-server
wget https://github.com/swagger-api/swagger-editor/releases/download/v2.10.4/swagger-editor.zip
unzip swagger-editor.zip
http-server swagger-editor
echo "Reference: https://swagger.io/docs/open-source-tools/swagger-editor/"
