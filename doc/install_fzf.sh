!#/bin/sh
echo "Will attempt to install fzf"

echo "Will attempt to execute: git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf"
git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf

echo "Will attempt to execute: ~/.fzf/install"
~/.fzf/install

if [ -f ${HOME}/.zshrc ]; then
  echo "Will attempt to append exports in fzf_exports.sh to ${HOME}/.zshrc"
  cat ${HOME}/dev-utils/doc/fzf_exports.sh >> ${HOME}/.zshrc
fi

if [ -f ${HOME}/.bashrc ]; then
  echo "Will attempt to append exports in fzf_exports.sh to ${HOME}/.bashrc"
  cat ${HOME}/dev-utils/doc/fzf_exports.sh >> ${HOME}/.bashrc
fi

echo "Will attempt to execute: sudo apt install fd-find"
sudo apt install fd-find

echo "You can periodically update fzf by executing:"
echo "cd ~/.fzf && git pull && ./install"


echo "Reference: https://github.com/junegunn/fzf"
