#!/bin/sh
echo "About to install zsh-autosuggestions"
source $HOME/.zshrc
git clone https://github.com/zsh-users/zsh-autosuggestions $ZSH_CUSTOM/plugins/zsh-autosuggestions
echo "source $ZSH_CUSTOM/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh" >> ~/.zshrc
echo "Add zsh-autosuggestions to the plugins() list in the $HOME/.zshrc file and then execute:"
echo "source $HOME/.zshrc"
echo "Reference: https://github.com/zsh-users/zsh-autosuggestions/blob/master/INSTALL.md"
