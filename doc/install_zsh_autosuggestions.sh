#!/bin/sh
echo "About to install zsh-autosuggestions"
git clone https://github.com/zsh-users/zsh-autosuggestions ~/.zsh/zsh-autosuggestions
echo "source ~/.zsh/zsh-autosuggestions/zsh-autosuggestions.zsh" >> ~/.zshrc
source ~/.zshrc
echo "Reference: https://github.com/zsh-users/zsh-autosuggestions/blob/master/INSTALL.md"