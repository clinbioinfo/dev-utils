#!/bin/sh
# Reference: https://shapeshed.com/zsh-corrupt-history-file/
mv ~/.zsh_history ~/.zsh_history_bad
strings ~/.zsh_history_bad > ~/.zsh_history
#fc -R ~/.zsh_history
rm ~/.zsh_history_bad
