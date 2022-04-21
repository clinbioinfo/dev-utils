#!/bin/bash

echo "Will install dependencies"
sudo apt install -y make build-essential libssl-dev zlib1g-dev \
libbz2-dev libreadline-dev libsqlite3-dev wget curl llvm libncurses5-dev \
libncursesw5-dev xz-utils tk-dev libffi-dev liblzma-dev python-openssl \
git

echo "Will git clone pyenv"
git clone https://github.com/pyenv/pyenv.git ~/.pyenv


echo "Will update ${HOME}/.zshrc"
echo 'export PYENV_ROOT="${HOME}/.pyenv"' >> ~/.zshrc
echo 'export PATH="$PYENV_ROOT/bin:$PATH"' >> ~/.zshrc
echo 'eval "$(pyenv init --path)"' >> ~/.zshrc

echo "Reference: https://k0nze.dev/posts/install-pyenv-venv-vscode/"
