cd ~

echo "About to install python3-pip"
sudo apt install python3-pip

echo "About to install setuptools"
pip3 install --upgrade setuptools

echo "About to install six"
pip3 install --upgrade six

echo "About to install pyscaffold[ALL]"
pip3 install --upgrade pyscaffold[ALL]

#echo "About to install coverage"
#sudo apt-get install python-dev gc
#sudo apt-get install python3-dev gcc
#pip3 install -U coverage

#echo "About to check the version of coverage installed"
#python -m coverage --version

echo "About to install pytest"
pip3 install -U pytest

echo "About to install the pytest-cov plug-in"
pip3 install -U pytest-cov

echo "If you think you'll want to execute distributed test deployment, execute the following"
echo "pip3 install -U pytest-xdist"

echo "About to install PyCharm"
cp ~/dev-utils/resources/pycharm-community-2017.3.2.tar.gz ~/.
tar zxvf pycharm-community-2017.3.2.tar.gz
rm pycharm-community-2017.3.2.tar.gz

echo "After you configure pycharm for the first time, you will be able to run it by executing: pycharm"
bash ~/pycharm-community-2017.3.2/bin/pycharm.sh

echo "All done"
