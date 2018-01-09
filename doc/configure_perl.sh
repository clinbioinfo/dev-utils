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

echo "About to install modules for dev-utils"
perlbrew use perl-5.27.4@devutils
cpanm Try::Tiny
cpanm Log::Log4perl
cpanm Config::IniFiles
cpanm Moose
cpanm File::Slurp
cpanm JSON::Parse
