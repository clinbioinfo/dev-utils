#!/bin/sh
echo "Will install pyspark"

echo "Will attempt to execute: sudo apt-get update"
sudo apt-get update

echo "Will attempt to execute: sudo apt-get install -y default-jre"
sudo apt-get install -y default-jre

echo "Will attempt to execute: sudo apt-get install -y scala"
sudo apt-get install -y scala

echo "The version of java installed:"
java -version

echo "The version of scala installed:"
scala -version

echo "Will attempt to execute: sudo apt-get install -y wget"
sudo apt-get install -y wget

echo "Will attempt to execute: wget https://apache.claz.org/spark/spark-3.1.1/spark-3.1.1-bin-hadoop2.7.tgz"
wget https://apache.claz.org/spark/spark-3.1.1/spark-3.1.1-bin-hadoop2.7.tgz

if [ -f spark-3.1.1-bin-hadoop2.7.tgz ]; then
  echo "Will execute: tar zxvf spark-3.1.1-bin-hadoop2.7.tgz"
  tar zxvf spark-3.1.1-bin-hadoop2.7.tgz
else
  echo "spark-3.1.1-bin-hadoop2.7.tgz is missing"
  exit 1
fi

if [ -d spark-3.1.1-bin-hadoop2.7 ]; then
  echo "Will attempt to execute: sudo chmod 777 spark-3.1.1-bin-hadoop2.7"
  sudo chmod 777 spark-3.1.1-bin-hadoop2.7
else
  echo "spark-3.1.1-bin-hadoop2.7 is missing"
  exit 1
fi

if [ -d spark-3.1.1-bin-hadoop2.7/python ]; then
  echo "Will attempt to execute: sudo chmod 777 spark-3.1.1-bin-hadoop2.7/python"
  sudo chmod 777 spark-3.1.1-bin-hadoop2.7/python
else
  echo "spark-3.1.1-bin-hadoop2.7/python is missing"
  exit 1
fi

if [ -d spark-3.1.1-bin-hadoop2.7/python/pyspark ]; then
  echo "Will attempt to execute: sudo chmod 777 spark-3.1.1-bin-hadoop2.7/python/pyspark"
  sudo chmod 777 spark-3.1.1-bin-hadoop2.7/python/pyspark
else
  echo "spark-3.1.1-bin-hadoop2.7/python/pyspark is missing"
  exit 1
fi

if [ -f ${HOME}/.bashrc ]; then
  echo "Will attempt to append some export statements to ${HOME}/.bashrc"
  cat pyspark_exports.sh >> ${HOME}/.bashrc
fi

if [ -f ${HOME}/.zshrc ]; then
  echo "Will attempt to append some export statements to ${HOME}/.zshrc"
  cat pyspark_exports.sh >> ${HOME}/.zshrc
fi


echo "Please execute the following next:"
echo "virtualenv venv -p python3"
echo "source venv/bin/activate"
echo "pip install jupyter"
echo "jupyter notebook"
echo "pip install py4j"
echo ""
echo "Then execute the following:"
echo "cd ${HOME}/spark-3.1.1-bin-hadoop2.7/python/pyspark/"
echo "mv resource resources"
echo "jupyter notebook"

