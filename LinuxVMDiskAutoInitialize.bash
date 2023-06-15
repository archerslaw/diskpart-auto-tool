#!/bin/bash
## NO ANY Exit if any untested command fails
set +o errexit

echo "##Ready to Auto initialize LinuxVM Disk##"
echo "Check growpart/resize2fs commands in Linux OS"
if [ ! -x /usr/bin/growpart ];then
	echo "Please install growpart tool"
	exit -1
fi

#if [ ! -x /usr/sbin/resize2fs ];then
#	echo "Please install resize2fs tool"
#	exit -2
#fi

auto_init_new_or_not_disk_main() {
	echo "Check the disk is new or not"
	DiskNum=0
	for Disk  in `fdisk -l 2>&1 | grep -o "Disk /dev/.*d[a-z]" | grep -v "/dev/vda" | awk '{print $2}'`;
	do
		lines=`hexdump -C -n 1048576 $Disk | wc -l`
		echo "Contain $lines lines from $Disk"
		if [ $lines -gt 3 ];then
			echo "Not a new disk, stop initializing and try to resizefs"
			disk_auto_growpart_resizefs
		else
			echo "It's a new disk and need to auto initializing"
			number=`ls /mnt/ | grep DataDisk | tail -1 | cut -d ":" -f 1 | tr -cd "[0-9]"`
			if [ -n "$number" ];then
				DiskNum=`expr $number + 1`
			fi
			UserMountPoint='/mnt/DataDisk'$DiskNum''
			single_disk_auto_init $UserMountPoint $Disk 'ext4'
		fi
	done
}

disk_auto_growpart_resizefs() {
    echo "Auto growpart and resizefs for the existing last disk partion"
	Lastpartition=`blkid $Disk* | tail -1`
	Partition=`echo $Lastpartition | cut -d ":" -f 1`
	PartitionNum=`echo $Partition | tr -cd "[0-9]"`
	if [ -n "$PartitionNum" ];then
		echo "on-line extending the existing partion to max size"
		growpart $Disk $PartitionNum 2>&1
		echo "on-line resizing '$Partition' partion filesystem"
		filesystem=`blkid $Partition | awk '{print $4}'`
		if [ $filesystem = 'TYPE="ext4"' ];then
			resize2fs -f $Partition 2>&1
		fi
	else
		echo "on-line resizing '$Partition' partion filesystem"
		filesystem=`blkid $Disk | awk '{print $4}'`
		if [ $filesystem = 'TYPE="ext4"' ];then
			resize2fs -f $Disk 2>&1
#		elif [ $filesystem = 'TYPE="xfs"' ];then
#			xfs_growfs $Disk 2>&1
		fi
	fi
}

single_disk_auto_init() {
	UserMountPoint=$1
	Disk=$2
	UserFileSystemType=$3
	echo 'Auto initializing single disk'$Disk''
	mkfs -t $UserFileSystemType $Disk 2>&1
	mkdir -p $UserMountPoint 2>&1
	UUID=`blkid $Disk | awk '{print $2}'`
	temp=`echo $Disk | sed 's;/;\\\/;g'`
	sed -i -e "/^$temp/d" /etc/fstab
	echo $UUID $UserMountPoint $UserFileSystemType 'defaults 0 0' >> /etc/fstab
	mount -a 2>&1
	echo 'Finish auto initializing single disk '$Disk', mounted on '$UserMountPoint' Dir'
}

auto_init_new_or_not_disk_main

df -h
blkid
cat /etc/fstab
echo 'List /etc/fstab and mounted Dir'
mount -l | grep DataDisk
