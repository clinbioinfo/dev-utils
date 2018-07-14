echo "About to install Perlbrew"
sudo apt-get install perlbrew -y

echo "About to init Perlbrew"
perlbrew init

echo "About to install perl-5.27.4"
perlbrew install perl-5.27.4

echo "About to enable install-cpanm"
perlbrew install-cpanm

echo "About to create lib perl-5.27.4@devutils"
perlbrew lib create perl-5.27.4@devutils

echo "About to use perl-5.27.4@devutils"
perlbrew use perl-5.27.4@devutils

echo "About to install modules for dev-utils"
echo "cat perlbrew-requirements.txt | perlbrew exec cpanm"
