#!/bin/bash
if [ $(uname -s) == "Linux" ] ; then 
	echo "enviroment runnign is Linux"
	if [ -e /etc/redhat-release ] ; then
		cat /etc/redhat-release;
	fi

	if [ -e /etc/lsb-release ]; then
	 	cat /etc/lsb-release;
	fi
fi 

if [ $(uname -s) == "FreeBSD" ] ; then 
	echo "enviroment runnign is FreeBSD"
fi 
