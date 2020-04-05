#!/bin/sh
echo "About to install emacs25"
sudo apt-get install emacs25 -y
echo ";;disable splash screen and startup message" >> ~/.emacs
echo "(setq inhibit-startup-message t)" >> ~/.emacs
echo "(setq initial-scratch-message nil)" >> ~/.emacs
