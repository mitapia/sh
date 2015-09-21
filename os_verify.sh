#!/bin/bash
os="$(uname -s)";

if [[ "$os" == "Linux" ]]; then
	# if vyatta
	if [[ "$(echo $SHELL)" == "/bin/vbash" ]]; then
		echo "Vyatta";
		exit 0;
	fi
	
	# if XenServer then dont run script
	if [[ -e /etc/redhat-release ]]; then
		if [[ "$(cat /etc/redhat-release)" == *"XenServer"* ]]; then
			echo "XenServer";
			exit 0;
		fi
	fi

	if [[ -e /etc/os-release ]]; then
		# retrive os name and version from file
        while IFS=\= read key value
        do
            if [[ "$key" == "ID" ]]; then
            	# **** need to remove quotations from value *****
            	id="${value//\"}";
            elif [[ "$key" == "VERSION_ID" ]]; then
            	version_id="${value//\"}";
            fi
        done < <(cat /etc/os-release)

		# if CentOS or RHEL, then check for ver.
		if [[ "$id" == "centos" ]] || [[ "$id" == "rhel" ]]; then
			yum -y install bc;	# required for the ver comparison to work
			if (( $(bc <<< "$version_id >= 7") )); then
				echo "CentOS or RedHat above v7";
				exit 0;
            fi
		fi
	fi

	echo "Other Linux";
	exit 0;

else
	echo "This OS has not been properly tested.  Please email the following results to mitapia@softlayer.com:";
	uname -a;
fi
