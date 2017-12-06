echo "About to execute sudo apt-get update"
sudo apt-get update

echo "About to install git"
sudo apt install git -y

echo "About install dev-utils"
cd ~
git clone https://github.com/clinbioinfo/dev-utils.git
cp ~/dev-utils/doc/aliases.txt ~/.
echo "source ~/aliases.txt" >> ~/.bashrc

echo "About to install chromium-browser"
sudo apt-get install chromium-browser -y

echo "About to install emacs"
sudo apt-get install emacs24 -y

echo "About to install Sublime Text"
wget -qO - https://download.sublimetext.com/sublimehq-pub.gpg | sudo apt-key add
echo "deb https://download.sublimetext.com/ apt/stable/" | sudo tee /etc/apt/sources.list.d/sublime-text.list


echo "About to install sublime text"
sudo apt-get update
sudo apt-get install sublime-text -y

echo "About to install python3-pip"
sudo apt install python3-pip

echo "About to install Perlbrew"
sudo apt-get install perlbrew -y

echo "About to init Perlbrew"
perlbrew init

echo "About to install perl-5.27.4"
perlbrew install perl-5.27.4
perlbrew install-cpanm

echo "About to create lib perl-5.27.4@devutils"
perlbrew lib create perl-5.27.4@devutils

echo "About to install modules for dev-utils"
perlbrew use perl-5.27.4@devutils
cpanm Try::Tiny
cpanm Log::Log4perl
cpanm Config::IniFiles
cpanm Moose
cpanm File::Slurp
cpanm JSON::Parse
