#!/bin/bash
echo "Will attempt to install core tools"
echo "source ${HOME}/dev-utils/doc/aliases.txt" >> ~/.bashrc
source ${HOME}/.bashrc
bash ${HOME}/dev-utils/doc/install_terminator.sh
sudo apt-get install tree -y
bash ${HOME}/dev-utils/doc/install_oh_my_zsh.sh
bash ${HOME}/dev-utils/doc/install_oh_my_zsh_part2.sh
bash ${HOME}/dev-utils/doc/install_zsh_autosuggestions.sh
bash ${HOME}/dev-utils/doc/install_zsh_syntax_highlighting.sh
echo "source ${HOME}/dev-utils/doc/aliases.txt" >> ~/.zshrc
python3 ${HOME}/dev-utils/util/update_oh_my_zsh_plugins.py
bash ${HOME}/dev-utils/doc/install_virtualenv.sh
bash ${HOME}/dev-utils/doc/install_pycharm_community_edition.sh
bash ${HOME}/dev-utils/doc/install_google_chrome_browser.sh
