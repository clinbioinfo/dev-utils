echo "Presume you've already installed git and cloned dev-utils like this:"
echo "sudo apt install git -y"
echo "and"
echo "cd ~ ; git clone https://github.com/clinbioinfo/dev-utils.git"

echo "About to execute sudo apt-get update"
sudo apt-get update

echo "source ~/dev-utils/doc/aliases.txt" >> ~/.bashrc

source ~/dev-utils/doc/install_google_chrome_browser.sh
source ~/dev-utils/doc/install_chromium_browser.sh
source ~/dev-utils/doc/install_emacs.sh
source ~/dev-utils/doc/install_terminator.sh
source ~/dev-utils/doc/install_tree.sh
source ~/dev-utils/doc/install_umlet.sh
source ~/dev-utils/doc/install_screen.sh
source ~/dev-utils/doc/install_sublime_text.sh
source ~/dev-utils/doc/install_vscode.sh

echo "Nice things to do now:"
echo "Add extensions in Chromium"
echo "Remove apps from Favorites"
