#!/bin/bash
os=$(uname -s);

if [ $os == "Linux" ]; then
	# if XenServer or ESX then dont run script
	# missiong test ESX
	if [[ -e /etc/redhat-release ]]; then
		#statements
	fi

	# if QuantaStore, raid_verify
	# missing test server

	# if vyatta - not working yet
	if [[ $(show version | grep -i vyatta | wc -l) -gt 0 ]]; then
		#statements
	fi

	# if CentOS or RHEL, then check for ver.
	# all other


else
	echo "This OS has not been properly tested.  Please email the following results to mitapia@softlayer.com:";
	uname -a;
fi
