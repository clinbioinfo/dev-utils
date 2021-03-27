!#/bin/sh
echo "Will attempt to install fzf"

echo "Will attempt to execute: git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf"
git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf

echo "Will attempt to execute: ~/.fzf/install"
~/.fzf/install

if [ -f ${HOME}/.zshrc ]; then
  echo "Will attempt to append the following to the ${HOME}/.zshrc"
  echo "export FZF_DEFAULT_OPS='--extended'" >> ${HOME}/.zshrc
fi

if [ -f ${HOME}/.bashrc ]; then
  echo "Will attempt to append the following to the ${HOME}/.bashrc"
  echo "export FZF_DEFAULT_OPS='--extended'" >> ${HOME}/.bashrc
fi

echo "You can periodically update fzf by executing:"
echo "cd ~/.fzf && git pull && ./install"


echo "Reference: https://github.com/junegunn/fzf"
