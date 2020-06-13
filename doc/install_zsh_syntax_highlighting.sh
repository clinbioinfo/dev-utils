#!/bin/sh
echo "About to install zsh-syntax-highlighting"
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git $ZSH_CUSTOM/plugins/zsh-syntax-highlighting
echo "source $ZSH_CUSTOM/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" >> $HOME/.zshrc
echo "Add zsh-syntax-highlighting to the plugins() list in the $HOME/.zshrc file and then execute:"
echo "source $HOME/.zshrc"
echo "Reference: https://gist.github.com/dogrocker/1efb8fd9427779c827058f873b94df95"
