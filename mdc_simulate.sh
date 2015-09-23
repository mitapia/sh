#!/bin/bash
os="$(uname -s)";

if [[ "$os" == "Linux" ]]; then
    # if vyatta
    if [[ "$(echo $SHELL)" == "/bin/vbash" ]]; then
        echo "Script is currently not supported for Vyatta devices, please procced with a manual MDC.";
        exit 0;
    fi
    
    # if XenServer then dont run script
    if [[ -e /etc/redhat-release ]]; then
        if [[ "$(cat /etc/redhat-release)" == *"XenServer"* ]]; then
            printf "If you are working on a reload or new provision with XenServer or VMware, DO NOT mount the drives. \n
                 Softly reboot the server, go into the RAID BIOS and verify the RAID setup and status from there.";
            exit 0;
        fi
    fi

    # check for 'parted'
    if ! hash parted 2>/dev/null; then
        # REQUIRED PACKAGE INSTALL
        if [[ -f /etc/redhat-release ]]; then
            yum -y install parted;
        else
            apt-get -y install parted;
        fi
        # reassurance it has been installed
        hash parted 2>/dev/null || { echo >&2 "Parted is required but it's not installed.  Aborting."; exit 1; }
    fi

    # store necessary variables
    number_drives=$( parted -lms | grep /dev/sd | grep -v /dev/sda -c );
    drives=( $( parted -lms | grep /dev/sd | grep -v /dev/sda | awk -F':' '{ print $1}' ) )

    $above_7="false"
    # checks for CentOS/RHEL ver 7 and above
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
            # REQUIRED PACKAGE INSTALL
            yum -y install bc;  # required for the ver comparison to work
            if (( $(bc <<< "$version_id >= 7") )); then
                $above_7="true";
            fi
        fi
    fi

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

    # Backup fstab before starting
    # cp /etc/fstab /root/fstab.bak;

    for drive in "$drives[@]"
    do
        #  check size of disk to be partitioned
        #  Less then 2TB - msdos
        #  More then 2TB - gpt

        # get size of drive
        drive_size="$( parted -sm /dev/sdb print unit GB | awk '{ FS=":"; NR==2; sub("GB", ""); print $2 }' )";

        # set in GB
        limit=$((2000))
        if [[ "$drive_size" -le "$limit" ]]
        then
            echo 'parted -s "$drive" mklabel msdos';
        else
            echo 'parted -s "$drive" mklabel gpt';
        fi

        echo 'parted -s "$drive" mkpart primary 1 -- -1';
        echo 'mkdir /disk"$n"';

        #  ext4 - up to 16TB
        #  xfs - 16TB-8EB  *per IS, CENTOS & RHEL v7 and above get XFS regardless of drive size
        fs_size=$((16*1000))    #GB
        if [[ "$above_7" == "false" ]] && [[ "$drive_size" -le "$fs_size" ]]; then
            fs=ext4;
        else
            fs=xfs;

            # if xfs not found to be installed, then procced to install
            if ! hash mkfs.xfs 2>/dev/null; then
                # REQUIRED PACKAGE INSTALL
                if [[ -f /etc/redhat-release ]]; then
                    yum -y install kmod-xfs.x86_64 xfsdump.x86_64 xfsprogs.x86_64;
                else
                    apt-get -y install xfsdump xfsprogs;
                fi  
                # reassurance it has been installed
                hash mkfs.xfs 2>/dev/null || { echo >&2 "mkfs.xfs is required but it's not installed.  Aborting."; exit 1; }
            fi
        fi

        echo 'mkfs.$fs -L /disk"$n" "$drive"1';
        echo "LABEL=/disk\"$n\" /disk$n \"$fs\" defaults 1 2"; # >> /etc/fstab;

        n=$(( n+1 ));
    done

    # mount -a;
    # df -h | grep /disk;
    
    adaptec_loations=(
        '/opt/Adaptec_Event_Monitor/arcconf'    # FreeBSD
        '/opt/StorMan/arcconf'          # FreeBSD
        '/usr/Adaptec_Event_Monitor/arcconf'
        '/usr/StorMan/arcconf'
    )

    # Adaptec
    for location in ${adaptec_loations[@]}; do
        if [[ -e $location ]]; then
            $location getstatus 1;
            $location getconfig 1 | grep "Controller\ Status\|Controller\ Model\|Logical\ device\ n\|Status\|RAID\ level";
            exit 0;
        fi
    done

    # LSI
    if [ -e /opt/MegaRAID/storcli/storcli64 ]; then
        /opt/MegaRAID/storcli/storcli64 /c0 show all|grep -A 36 "VD LIST :";
        exit 0;
    fi

    # if script got this far then no RAID software was found
    echo "No RAID software was found! Is this server supposed to be Onboard?";
    exit 0;
else
    echo "This OS has not been properly tested.  Please email the following results to mitapia@softlayer.com:";
    uname -a;
fi