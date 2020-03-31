#!/bin/sh
echo "Going to install oh-my-zsh"
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

echo "Going to append the dev-utils/doc/aliases.txt to ~/.zshrc"
echo "source ~/dev-utils/doc/aliases.txt" >> ~/.zshrc