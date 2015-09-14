#!/bin/sh

# store necessary variables
number_drives=$( parted -lms | grep /dev/sd | grep -v /dev/sda -c );
drives=( $( parted -lms | grep /dev/sd | grep -v /dev/sda | awk -F':' '{ print $1}' ) )

# check for secondary drives
if [ $formating_drives -le 0 ]; then
	echo "No secondary drives found";
	exit 0;
fi

if [ $formating_drives -ge 26 ]; then
	echo "Script currently does not support formating more then 25 drives.";
	exit 0;
fi

# check the secondary drives for existing partitions
for drive in ${drives[@]}; do
	# check for error reading device

	if [ $( parted -sm $drive print | wc -l ) -gt 2 ]; then
		echo "Drive " $drive "has partitions."
		echo "This is either a Reload and should no go through an MDC, drives have already been partitioned, or this drive was not properly Reclamed.";
		echo "If these drives came from another server and where not formated, replace and change the status to Format in IMS.";
		exit 0;
	fi
done
