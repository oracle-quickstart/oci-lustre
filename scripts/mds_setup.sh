#/bin/bash

set -x
enable_mdt_raid0=$1
uname -a

sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config
getenforce
modprobe lnet
lnetctl lnet configure
lctl list_nids
nic_25gbps=false
nic_100gbps=false
# For compute instances having ethernet network bandwidth less than 25 gbps
ifconfig | grep "ens3: "

if [ $? -eq 0 ]; then
  echo "true";
  lnetctl net add --net tcp1 --if ens3
else
  # TODO - Add logic to use nic_100gbps RDMA first if its configured already.  Look for ethernet interface with name:  enp94s0f0.  
  # This interface should be used instead of eno2, if its already setup for RMDA cluster
  # For compute instances having nic_25gbps ethernet bandwidth speed 
  ifconfig | grep "eno2: "
  if [ $? -eq 0 ]; then
    echo "Found nic_25gbps network interface";
    nic_25gbps=true
    lnetctl net add --net tcp1 --if eno2
  else
    echo "Expected network inferface missing, abort deployment";
    exit 1;
  fi
fi


disk_mount () {
if [ $enable_mdt_raid0 = "true" ]; then
  echo -e "Create stripe RAID of $dcount $disk_type disk ."
  mount_device="/dev/md/md_$disk_type"
  device_list=""
  raid_level="raid0"
  if [ $disk_type = "nvme" ]; then
    device_list="/dev/nvme[0-$((total_disk_count-1))]n1"
  else
    device_list="/dev/sd[${drive_variables}]"
  fi

#  # We need min 4 disk to create RAID6, else use RAID0
#  if [ $dcount -ge 4 ]; then
#    raid_level="raid6"
#  else
#    raid_level="raid0"
#  fi
  echo -e "RAID level of $raid_level for $dcount $disk_type disk ."
  echo "DEVICE $device_list" >  /etc/mdadm.conf
  echo "ARRAY ${mount_device} devices=$device_list" >> /etc/mdadm.conf
  mdadm -C ${mount_device} --level=$raid_level --raid-devices=$dcount $device_list 

fi


if [ $disk_type = "nvme" ]; then
  fsname=lfsnvme
  mount_point="/mnt/mdt_$disk_type"
else
  fsname=lfsbv
  mount_point="/mnt/mdt_$disk_type"
fi 
mount_point="/mnt/mds${num}_mdt${index}_${disk_type}"
mgs_ip=`nslookup lustre-mds-server-1 | grep "Address: " | gawk '{ print $2 }'` ; echo $mgs_ip
mgs_pri_nid=$mgs_ip@tcp1 ;  echo $mgs_pri_nid

if [ ! $mgs_exist -eq 1 ]; then
  # Change index value, only when you have more than 1 MDS servers.  Each MDS will have its own MDT. 
  mkfs.lustre --fsname=$fsname --index=$index   --mgs --mdt $mount_device
  mgs_exist=1
else
  mkfs.lustre --fsname=$fsname --index=$index  --mdt $mount_device   --mgsnode $mgs_pri_nid 
fi

lctl network up
lctl list_nids
mkdir -p $mount_point
mount -t lustre $mount_device $mount_point

## Update fstab
echo "$mount_device               $mount_point           lustre  defaults,_netdev        0 0" >> /etc/fstab

}


mgs_exist=0
num=`hostname | gawk -F"." '{ print $1 }' | gawk -F"-"  'NF>1&&$0=$(NF)'`
hostname
echo $num

if [ $num -ge 2 ]; then
  mgs_exist=1
fi


disk_type=""
drive_variables=""
drive_letter=""
dcount=0
index=-1
total_disk_count=`ls /dev/ | grep nvme | grep n1 | wc -l`
for disk in `ls /dev/ | grep nvme | grep n1`; do
  echo -e "\nProcessing /dev/$disk"
  disk_type="nvme"
  pvcreate -y  /dev/$disk
  mount_device="/dev/$disk"
  index=$((((((num-1))*total_disk_count))+dcount))
  echo $index 
  if [ $enable_mdt_raid0 = "true" -a $total_disk_count -gt 1 ]; then
    echo "wait to loop through all disk"
  else
    disk_mount
  fi

  dcount=$((dcount+1))
#  index=$((index+1))
done;

echo "$dcount $disk_type disk found"

if [ $enable_mdt_raid0 = "true" -a $total_disk_count -gt 1 ]; then
  disk_mount
fi


disk_type=""
drive_variables=""
drive_letter=""
dcount=0
index=-1
total_disk_count=`cat /proc/partitions | grep -ivw 'sda' | grep -ivw 'sda[1-3]' | grep -iv nvme  | sed 1,2d | gawk '{print $4}' | grep "^sd" | wc -l`
for disk in `cat /proc/partitions | grep -ivw 'sda' | grep -ivw 'sda[1-3]' | grep -iv nvme  | sed 1,2d | gawk '{print $4}' | grep "^sd" `; do
  echo -e "\nProcessing /dev/$disk"
  disk_type="bv"
  pvcreate -y  /dev/$disk
  mount_device="/dev/$disk"

  index=$((((((num-1))*total_disk_count))+dcount))
  echo $index  
  drive_letter=`echo $disk | sed 's/sd//'`
  drive_variables="${drive_variables}${drive_letter}"
  if [ $enable_mdt_raid0 = "true" -a $total_disk_count -gt 1 ]; then
    echo "wait to loop through all disk"
  else
    disk_mount
  fi
  dcount=$((dcount+1))
done;

echo "$dcount $disk_type disk found"

if [ $enable_mdt_raid0 = "true" -a $total_disk_count -gt 1 ]; then
  disk_mount
fi

# Performance tuning 
lctl set_param -P obdfilter.*.readcache_max_filesize=2M

service lustre status
lctl list_nids
nids=`lctl list_nids` | grep tcp1
echo $nids

df -h


# Update lnet service to start with correct config and enable at boot time
lnet_service_config="/usr/lib/systemd/system/lnet.service"
cp $lnet_service_config $lnet_service_config.backup
search_string="ExecStart=/usr/sbin/lnetctl import /etc/lnet.conf"
if [ $nic_25gbps ]; then
  nic_add="ExecStart=/usr/sbin/lnetctl net add --net tcp1 --if eno2"
else
  nic_add="ExecStart=/usr/sbin/lnetctl net add --net tcp1 --if ens3"
fi
sed -i "s|$search_string|#$search_string\n$nic_add|g" $lnet_service_config
# To comment ConditionPathExists clause
sed -i "s|ConditionPathExists=!/proc/sys/lnet/|#ConditionPathExists=!/proc/sys/lnet/|g" $lnet_service_config

systemctl status lnet
systemctl enable lnet

echo "setup complete"
set +x


