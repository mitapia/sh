#!/bin/bash

echo "DO NOT attempt to run script, not working yet!!";
exit 0;

### CORE ###

# Backup fstab before starting
cp /etc/fstab /root/fstab.bak

for drive in "$drives[@]"
do
#  check size of disk to be partitioned
#  Less then 2TB - msdos
#  More then 2TB - gpt

# makes sure that i did not miss any zeros
	drive_size = $();

    limit=$((2*1000*1000*1000*1000))
    if [ "$drive_size" -le $limit ]
    then
        parted -s "$drive" mklabel msdos;
    else
        parted -s "$drive" mklabel gpt;
    fi

    parted -s "$drive" mkpart primary 1 -- -1;
    mkdir /disk$n;

#  ext4 - up to 16TB
#  xfs - 16TB-8EB  *per IS, CENTOS & RHEL v7 and above get XFS regardless of drive size
    fs_size=$((16*1000*1000*1000*1000))
    if [[ "$above_7" == "true" ]]; then
		fs=xfs;
    elif [[ "$drive_size" -le $fs_size ]]; then
        fs=ext4;
    else
        fs=xfs;
    fi

    mkfs.$fs -L /disk$n "$drive"'1';
    echo "LABEL=/disk$n /disk$n $fs defaults 1 2" >> /etc/fstab;

    n=$(( n+1 ));
done

mount -a;
parted -l;
df -h | grep /disk;

exit 0
