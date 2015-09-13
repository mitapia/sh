#!/bin/bash
if [ -e /etc/redhat-release ] ; then
	cat /etc/redhat-release;
fi

if [ -e /etc/lsb-release ]; then
 	cat /etc/lsb-release;
fi
