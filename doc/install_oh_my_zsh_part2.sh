#!/bin/sh
echo "Going to append the dev-utils/doc/aliases.txt to ~/.zshrc"
echo "source ~/dev-utils/doc/aliases.txt" >> ~/.zshrc
echo "export ZSH_CUSTOM=$HOME/.oh-my-zsh" >> $HOME/.zshrc
echo "You need to execute:"
echo "source ${HOME}/.zshrc"
