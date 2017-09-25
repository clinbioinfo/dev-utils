echo "About to execute sudo apt-get update"
sudo apt-get update
echo "About to install chromium-browser"
sudo apt-get install chromium-browser
echo "About to install emacs"
sudo apt-get install emacs24
echo "About to install Sublime Text"
wget -qO - https://download.sublimetext.com/sublimehq-pub.gpg | sudo apt-key add
echo "deb https://download.sublimetext.com/ apt/stable/" | sudo tee /etc/apt/sources.list.d/sublime-text.list
sudo apt-get install sublime-text
echo "About to install git"
sudo apt install git
