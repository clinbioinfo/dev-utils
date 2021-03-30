#!/bin/bash
echo "Will attempt to install core tools (part 1)"
echo "source ${HOME}/dev-utils/doc/aliases.txt" >> ~/.bashrc
source ${HOME}/.bashrc
bash ${HOME}/dev-utils/doc/install_terminator.sh
sudo apt-get install tree -y
bash ${HOME}/dev-utils/doc/install_oh_my_zsh.sh
