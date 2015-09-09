#!/bin/bash

adaptec_loations=(
	'/opt/Adaptec_Event_Monitor/arcconf'	# FreeBSD
	'/opt/StorMan/arcconf'			# FreeBSD
	'/usr/Adaptec_Event_Monitor/arcconf'
	'/usr/StorMan/arcconf'
)

# Adaptec
for location in ${adaptec_loations[@]}; do
	if [[ -a $location ]]; then
		$location getconfig 1;
		exit;
	fi
done

# LSI
if [ -a /opt/MegaRAID/storcli/storcli64 ]; then
	/opt/MegaRAID/storcli/storcli64 /c0 show all|grep -A 36 "VD LIST :";
	exit;
fi

# if script got this far then no RAID software was found
echo "No RAID software was found! Is this server supposed to be Onboard?"
