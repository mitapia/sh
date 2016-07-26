#!/bin/bash
# Colors
    txtund=$(tput sgr 0 1)          # Underline
    txtbld=$(tput bold)             # Bold

    Black="$(tput setaf 0)"
    BlackBG="$(tput setab 0)"
    DarkGrey="$(tput bold ; tput setaf 0)"
    LightGrey="$(tput setaf 7)"
    LightGreyBG="$(tput setab 7)"
    White="$(tput bold ; tput setaf 7)"
    Red="$(tput setaf 1)"
    RedBG="$(tput setab 1)"
    LightRed="$(tput bold ; tput setaf 1)"
    Green="$(tput setaf 2)"
    GreenBG="$(tput setab 2)"
    LightGreen="$(tput bold ; tput setaf 2)"
    Brown="$(tput setaf 3)"
    BrownBG="$(tput setab 3)"
    Yellow="$(tput bold ; tput setaf 3)"
    Blue="$(tput setaf 4)"
    BlueBG="$(tput setab 4)"
    LightBlue="$(tput bold ; tput setaf 4)"
    Purple="$(tput setaf 5)"
    PurpleBG="$(tput setab 5)"
    Pink="$(tput bold ; tput setaf 5)"
    Cyan="$(tput setaf 6)"
    CyanBG="$(tput setab 6)"
    LightCyan="$(tput bold ; tput setaf 6)"
    NC="$(tput sgr0)"       # No Color

function raid_verify() {
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
            return 0;
        fi
    done

    # LSI
    if [[ -e /opt/MegaRAID/storcli/storcli64 ]]; then
        /opt/MegaRAID/storcli/storcli64 /c0 show all|grep -A 36 "VD LIST :";
        return 0;
    fi    

    printf "${Yellow}No RAID software was found! Is this server supposed to be Onboard?${NC}\n";        
    return 
}

os="$(uname -s)";

if [[ "$os" == "Linux" ]]; then
    # if vyatta
    if [[ "$(echo $SHELL)" == "/bin/vbash" ]]; then
        printf "${Yellow}Script is currently not supported for Vyatta devices, please procced with a manual MDC.${NC}\n";
        raid_verify;
        printf "${GreenBG}${Black}Enter 'exit' to finalize script:${NC}\n";
        exit 0;
    fi
    
    # if XenServer then dont run script
    if [[ -e /etc/redhat-release ]]; then
        if [[ "$(cat /etc/redhat-release)" == *"XenServer"* ]]; then
            printf "If you are working on a reload or new provision with XenServer or VMware, DO NOT mount the drives. \n
                 Softly reboot the server, go into the RAID BIOS and verify the RAID setup and status from there.";
            echo "Enter 'exit' to finalize script:";
            exit 1;
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
        hash parted 2>/dev/null || { 
            printf >&2 "${RedBG}Parted is required but it's not installed.  Aborting.${NC}\n"; 
            printf "${GreenBG}${Black}Enter 'exit' to finalize script:${NC}\n";
            exit 1; 
        }
    fi

    # 
    touch ~/.bash_profile && cp ~/.bash_profile ~/.bash_profile.bak;
    echo "source ~/.progress" >> ~/.bash_profile; 
    #echo "logout;" >> ~/.bash_profile; ## move to .progress

    # foudn that dabian comes with /dev/fd0 and makes parted stall
    # solution found here:  http://unix.stackexchange.com/questions/53513/linux-disable-dev-fd0-floppy
    if [[ $( cat /etc/fstab | grep /dev/fd0 | wc -l ) -gt 0 ]]; then
        echo "blacklist floppy" | tee /etc/modprobe.d/blacklist-floppy.conf;
        rmmod floppy;
        update-initramfs -u;
    fi

    # store necessary variables
    number_drives=$( parted -lms | grep /dev/sd | grep -vw /dev/sda -c );
    if ( parted -lms | grep Error ); then
        # must find a way to work aroud 'Error: /dev/sdab: unrecognised disk label'
        printf "${Yellow}Parted has reported Erros, stoppig script.${NC}\n";
        parted -lms | grep Error;
        printf "${GreenBG}${Black}Enter 'exit' to finalize script:${NC}\n";
        exit 0;
    fi
    drives=( $( parted -lms | grep /dev/sd | grep -vw /dev/sda | awk -F':' '{ print $1}' ) )

    above_7="false"
    # checks for CentOS/RHEL ver 7 and above
    if [[ -e /etc/os-release ]]; then
        # retrive os name and version from file
        while IFS=\= read key value
        do
            if [[ "$key" == "ID" ]]; then
                # need to remove quotations from value
                id="${value//\"}";
            elif [[ "$key" == "VERSION_ID" ]]; then
                version_id="${value//\"}";
            fi
        done < <(cat /etc/os-release)

        # if CentOS or RHEL, then check for ver.
        if [[ "$id" == "centos" ]] || [[ "$id" == "rhel" ]]; then
            if (( $(bc <<< "$version_id >= 7") )); then
                above_7="true";
            fi
        fi
    fi

    # check for secondary drives
    if [[ $number_drives -le 0 ]]; then
        printf "${Yellow}No secondary drives found${NC}\n";
        raid_verify;
        printf "${GreenBG}${Black}Enter 'exit' to finalize script:${NC}\n";
        exit 0;
    fi

    # check the secondary drives for existing partitions
    for drive in ${drives[@]}; do
        # check for error reading device
        if [[ $( parted -sm $drive print | grep Error | wc -l ) -gt 0 ]]; then
            printf "${RedBG}Error reading drive $drive. Aborting.${NC}\n";
            printf "${GreenBG}${Black}Enter 'exit' to finalize script:${NC}\n";
            exit 1;
        fi

        if [[ $( parted -sm $drive print | wc -l ) -gt 2 ]]; then
            printf "${Red}Drive $drive has partitions.${NC}\n"
            echo "The partitions for the secondary disk(s) were already set. This could have been because the partitions were already defined for the provision or because this is a Reload.";
            echo "This could also happen if the drive was not properly formatted during the Reclaim process, which will require you to replace the drive and make sure it is formatted correctly.";
            printf "\n\n";  # just want some empty lines
            tput setaf 2;   # Green
            df -h | grep -vw "/dev/sda\|tmpfs";
            tput sgr0;      # No color
            raid_verify;
            printf "${GreenBG}${Black}Enter 'exit' to finalize script:${NC}\n";
            exit 1;
        fi
    done

    # Backup fstab before starting
    # cp /etc/fstab /root/fstab.bak;

    n=1;
    for drive in "${drives[@]}"
    do
        #  check size of disk to be partitioned
        #  Less then 2TB - msdos
        #  More then 2TB - gpt

        # get size of drive
        drive_size="$( parted -sm $drive print unit GB | awk '{ FS=":"; NR==2; sub("GB", ""); print $2 }' )";

        # set in GB
        limit=$((2000))
        if (( $(bc <<< "$drive_size <= $limit") )); then
            echo "parted -s $drive mklabel msdos";
        else
            echo "parted -s $drive mklabel gpt";
        fi

        echo "parted -s $drive mkpart primary 1 -- -1";
        echo "mkdir /disk$n";

        #  ext4 - up to 16TB
        #  xfs - 16TB-8EB  *per IS, CENTOS & RHEL v7 and above get XFS regardless of drive size
        fs_size=$((16*1000))    #GB
        if [[ "$above_7" == "false" ]] && (( $(bc <<< "$drive_size <= $fs_size") )); then
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

        echo "mkfs.$fs -L /disk$n ${drive}1";
        echo "LABEL=/disk$n /disk$n $fs defaults 1 2"; # >> /etc/fstab;

        n=$(( n+1 ));
    done

    # mount -a;
    # df -h | grep /disk;
    rm ~/.progress
    mv ~/.bash_profile.bak ~/.bash_profile;
    
    raid_verify;
    printf "${Green}Press Ctrl-A and then ESC to scroll up.\n Press ESC again to exit scrollback mode.${NC}\n";
    printf "${GreenBG}${Black}Enter 'exit' to finalize script:${NC}\n";
    exit 0;
else
    printf "${RedBG}This OS has not been properly tested.  Please email the following results to mitapia@softlayer.com:${NC}\n";
    uname -a;
    printf "${GreenBG}${Black}Enter 'exit' to finalize script:${NC}\n";
    exit 1;
fi
