#!/bin/sh
echo "Going to append the .tools/dev-utils/doc/aliases.txt to ~/.zshrc"
echo "source ~/.tools/dev-utils/doc/aliases.txt" >> ~/.zshrc
echo "export ZSH_CUSTOM=$HOME/.oh-my-zsh" >> $HOME/.zshrc
echo "You need to execute:"
echo "source ${HOME}/.zshrc"
