#/bin/bash

set -x

uname -a

sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config
getenforce
modprobe lnet
lnetctl lnet configure
lctl list_nids
lnetctl net add --net tcp1 --if ens3
mds_ip=`nslookup lustre-mds-server-1 | grep "Address: " | gawk '{ print $2 }'` ; echo $mds_ip


drive_variables=""
drive_letter=""
dcount=0
for disk in `cat /proc/partitions | grep -ivw 'sda' | grep -ivw 'sda[1-3]' | sed 1,2d | gawk '{print $4}'`; do
  echo -e "\nProcessing /dev/$disk"
  pvcreate -y  /dev/$disk
  mount_device="/dev/$disk"
  drive_letter=`echo $disk | sed 's/sd//'`
  drive_variables="${drive_variables}${drive_letter}"
  dcount=$((dcount+1))
done;

echo "$dcount BV found"

if [ $dcount -gt 1 ]; then
  echo -e "OST - Create stripe RAID0 of $dcount Block Volumes ."
  mount_device="/dev/md0"
  echo "DEVICE /dev/sd[${drive_variables}]" >  /etc/mdadm.conf
  echo "ARRAY ${mount_device} devices=/dev/sd[${drive_variables}]" >> /etc/mdadm.conf
  mdadm -C ${mount_device} --level=raid0 --raid-devices=$dcount /dev/sd[${drive_variables}]

else
  if [ $dcount -eq 1 ]; then
    echo -e "OST - Single Block Volume."
  else
    echo "NO OST"
  fi
fi

num=`hostname | gawk -F"." '{ print $1 }' | gawk -F"-"  'NF>1&&$0=$(NF)'`

mkfs.lustre --ost --fsname=lustrefs --index=`expr ${num} - 1` --mgsnode=${mds_ip}@tcp1 $mount_device
#lctl network up
#lctl list_nids
mount_dir="/ostoss_mount${num}"
mkdir -p $mount_dir
mount -t lustre $mount_device $mount_dir

## Update fstab
cp /etc/fstab /etc/fstab.backup
echo "$mount_device               $mount_dir           lustre  defaults,_netdev        0 0" >> /etc/fstab

service lustre status
lctl list_nids
nids=`lctl list_nids` | grep tcp1
echo $nids
df -h

echo "setup complete"
set +x

