#!/bin/bash

echo "For install procedure, see install_apache_spark.sh"

echo ""
echo "Add the following two lines to your ~/.bashrc or ~/.zshrc:"
echo "export SPARK_HOME=/opt/spark"
echo "export PATH=\$PATH:$SPARK_HOME/bin:\$SPARK_HOME/sbin"
echo "export PYSPARK_PYTHON=python3"
echo "and then source ~/.bashrc or ~/.zshrc"


echo ""
echo "The start-slave.sh command is used to start Spark Worker Process."
echo "\$SPARK_HOME/sbin/start-slave.sh spark://ubuntu:7077"

echo ""
echo "Use the spark-shell command to access Spark Shell:"
echo "\$SPARK_HOME/bin/spark-shell"

echo ""
echo "Use the Python Spark shell:"
echo "\$SPARK_HOME/bin/pyspark"

echo ""
echo "To shut down the master and slave:"
echo "\$SPARK_HOME/sbin/stop-slave.sh"
echo "\$SPARK_HOME/sbin/stop-master.sh"
