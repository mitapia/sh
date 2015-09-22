#!/bin/bash
# random command to test the dowload and running of script using screen
hostname; 
echo $SHELL;
if [ -f /etc/redhat-release ]; then
	echo "yum here";
else
	echo "apt-get here";
fi
