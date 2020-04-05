#!/bin/sh
echo "About to install zsh-syntax-highlighting"
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting
echo "Add zsh-syntax-highlighting to the plugins section in the ~/.zshrc"
