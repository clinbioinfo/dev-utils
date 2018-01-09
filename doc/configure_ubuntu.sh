echo "Presume you've already installed git and cloned dev-utils like this:"
echo "sudo apt install git -y"
echo "and"
echo "cd ~ ; git clone https://github.com/clinbioinfo/dev-utils.git"

echo "About to execute sudo apt-get update"
sudo apt-get update

cd ~
cp ~/dev-utils/doc/aliases.txt ~/.
echo "source ~/aliases.txt" >> ~/.bashrc

echo "About to install chromium-browser"
sudo apt-get install chromium-browser -y

echo "About to install emacs25"
sudo apt-get install emacs25 -y

echo "About to install terminator"
sudo apt-get install terminator -y

echo "About to install Sublime Text"
wget -qO - https://download.sublimetext.com/sublimehq-pub.gpg | sudo apt-key add
echo "deb https://download.sublimetext.com/ apt/stable/" | sudo tee /etc/apt/sources.list.d/sublime-text.list

echo "About to install sublime text"
sudo apt-get update
sudo apt-get install sublime-text -y

echo "Nice things to do now:"
echo "Add extensions in Chromium"
echo "Remove apps from Favorites"
