#/bin/bash

set -x
enable_mdt_raid0=$1
mgs_fqdn_hostname_nic0=$2
mgs_fqdn_hostname_nic1=$3
uname -a

source /tmp/env_variables.sh

sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config
getenforce
modprobe lnet
lnetctl lnet configure
lctl list_nids
nodeWith2NIC=0
# BM.Standard and BM.DenseIO shapes have 2 NICs and their 2nd NIC are labeled as below: 
ifconfig | grep "^eno3d1:\|^enp70s0f1d1:"
  if [ $? -eq 0 ] ; then
    echo "Shapes with 2 NIC setup, except hpc shapes"
    nodeWith2NIC=1
    #mgs_hostname_prefix=$mgs_hostname_prefix_nic1
    ifconfig | grep "^enp70s0f1d1:"
      if [ $? -eq 0 ] ; then
        interface="enp70s0f1d1"
      else
        interface="eno3d1"
      fi
    else
      ifconfig | grep "eno2: "
      if [ $? -eq 0 ]; then
        echo "Found HPC shape, using NIC with 25gbps network interface";
        #nic_25gbps=true
        interface="eno2"
        #mgs_hostname_prefix=$mgs_hostname_prefix_nic0
      else
        # For compute instances having ethernet network bandwidth less than 25 gbps
        ifconfig | grep "ens3: "
        if [ $? -eq 0 ]; then
           interface="ens3"
           #mgs_hostname_prefix=$mgs_hostname_prefix_nic0
        fi 
      fi 
    fi

if [ $nodeWith2NIC -eq 1 ]; then 
  ip route
  ifconfig
  route
  ip addr

      
  # Wait till 2nd NIC is configured, since the Lustre cluster will use the 2nd NIC for cluster comm. 
  privateIp=`curl -s http://169.254.169.254/opc/v1/vnics/ | jq '.[1].privateIp' | sed 's/"//g' ` ; echo $privateIp
  while [ -z "$privateIp" -o $privateIp = "null" ];
  do
    sleep 10s
    echo "Waiting for 2nd Physical NIC to get configured with hostname"
    privateIp=`curl -s http://169.254.169.254/opc/v1/vnics/ | jq '.[1].privateIp' | sed 's/"//g' ` ; echo $privateIp
  done
  echo "Server nodes with 2 NICs - get hostname for 2nd NIC..."
      

      
  privateIp=`curl -s http://169.254.169.254/opc/v1/vnics/ | jq '.[1].privateIp' | sed 's/"//g' ` ; echo $privateIp
  macAddr=`curl -s http://169.254.169.254/opc/v1/vnics/ | jq '.[1].macAddr' | sed 's/"//g' ` ; echo $macAddr
  subnetCidrBlock=`curl -s http://169.254.169.254/opc/v1/vnics/ | jq '.[1].subnetCidrBlock' | sed 's/"//g' ` ; echo $subnetCidrBlock
  vnicId=`curl -s http://169.254.169.254/opc/v1/vnics/ | jq '.[1].vnicId' | sed 's/"//g' ` ; echo $vnicId


  echo "$subnetCidrBlock via $privateIp dev $interface" >  /etc/sysconfig/network-scripts/route-$interface

echo "DEVICE=$interface
HWADDR=$macAddr
ONBOOT=yes
TYPE=Ethernet
USERCTL=no
IPADDR=$privateIp
NETMASK=255.255.255.0
MTU=9000" > /etc/sysconfig/network-scripts/ifcfg-$interface

  # make the change now
  ip link set dev $interface mtu 9000

  systemctl status network.service
  # You might see some DHCP error, ignore it.  Its not impacting any functionality I know of.
  systemctl restart network.service

  ip route ; ifconfig ; route ; ip addr ;

  # Add logic to ensure the below is not empty
    cmd=`nslookup $privateIp | grep -q "name = "`
    while [ $? -ne 0 ];
    do
      echo "Waiting for nslookup..."
      sleep 10s
      cmd=`nslookup $privateIp | grep -q "name = "`
    done

  SecondNicFQDNHostname=`nslookup $privateIp | grep "name = " | gawk -F"=" '{ print $2 }' | sed  "s|^ ||g" | sed  "s|\.$||g"`
  THIS_FQDN=$SecondNicFQDNHostname
  THIS_HOST=${THIS_FQDN%%.*}
  SecondNICDomainName=${THIS_FQDN#*.*} 
  echo $SecondNICDomainName
  #primaryNICHostname="`hostname`"
  #sed -i "s/^PRESERVE_HOSTINFO=0/PRESERVE_HOSTINFO=3/g" /etc/oci-hostname.conf  
  #cat /etc/oci-hostname.conf
else
  # Servers with only 1 physical NIC or HPC shapes

    curl -O https://docs.cloud.oracle.com/en-us/iaas/Content/Resources/Assets/secondary_vnic_all_configure.sh
    chmod +x secondary_vnic_all_configure.sh
    ./secondary_vnic_all_configure.sh -c 

     cd /etc/sysconfig/network-scripts/

    # Wait till 2nd NIC is configured
    privateIp=`curl -s http://169.254.169.254/opc/v1/vnics/ | jq '.[1].privateIp ' | sed 's/"//g' ` ;
    echo $privateIp | grep "\." ;
    while [ $? -ne 0 ];
    do
      sleep 10s
      echo "Waiting for 2nd Physical NIC to get configured with hostname"
      privateIp=`curl -s http://169.254.169.254/opc/v1/vnics/ | jq '.[1].privateIp ' | sed 's/"//g' ` ;
      echo $privateIp | grep "\." ;
    done

    macAddr=`curl -s http://169.254.169.254/opc/v1/vnics/ | jq '.[1].macAddr ' | sed 's/"//g' ` ;
    subnetCidrBlock=`curl -s http://169.254.169.254/opc/v1/vnics/ | jq '.[1].subnetCidrBlock ' | sed 's/"//g' ` ;

    interface=`ip addr | grep -B2 $privateIp | grep "BROADCAST" | gawk -F ":" ' { print $2 } ' | sed -e 's/^[ \t]*//'`

    echo "$subnetCidrBlock via $privateIp dev $interface" >  /etc/sysconfig/network-scripts/route-$interface
    echo "Permanently configure 2nd NIC...$interface"
    echo "DEVICE=$interface
HWADDR=$macAddr
ONBOOT=yes
TYPE=Ethernet
USERCTL=no
IPADDR=$privateIp
NETMASK=255.255.255.0
MTU=9000
NM_CONTROLLED=no
" > /etc/sysconfig/network-scripts/ifcfg-$interface

    # Intel or AMD
    lscpu | grep "Vendor ID:"  | grep "AuthenticAMD"
    if [ $? -eq 0 ];  then
      echo "do nothing"
    else
      echo Intel
      # For Intel shapes only
      echo "ETHTOOL_OPTS=\"-G ${interface} rx 2047 tx 2047 rx-jumbo 8191; -L ${interface} combined 74\"" >> /etc/sysconfig/network-scripts/ifcfg-$interface
    fi

    systemctl status network.service
    ifdown $interface
    ifup $interface



  # THIS_FQDN="`hostname --fqdn`"
  # THIS_HOST="${THIS_FQDN%%.*}"
  SecondVNicFQDNHostname=`nslookup $privateIp | grep "name = " | gawk -F"=" '{ print $2 }' | sed  "s|^ ||g" | sed  "s|\.$||g"`
  THIS_FQDN=$SecondVNicFQDNHostname
  THIS_HOST=${THIS_FQDN%%.*}
  SecondVNICDomainName=${THIS_FQDN#*.*}
 
fi


lnetctl net add --net tcp1 --if $interface –peer-timeout 180 –peer-credits 128 –credits 1024



# function
disk_mount () {
cp /etc/mdadm.conf /etc/mdadm.conf.backup
if [ $enable_mdt_raid0 = "true" -a $total_disk_count -gt 1 ]; then
  echo -e "Create stripe RAID of $dcount $disk_type disk ."
  mount_device="/dev/md/md_$disk_type"
  device_list=""
  # reset index to align with node num-1, when raid0 is enabled, since there will be only 1 disk per node.  
  index=$((num-1))
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
  echo "DEVICE $device_list" >>  /etc/mdadm.conf
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


#if [ "$mds_dual_nics" = "true" ]; then
  # Add logic to ensure the below is not empty
    cmd=`nslookup ${mgs_fqdn_hostname_nic1} | grep -qi "Name:"`
    while [ $? -ne 0 ];
    do
      echo "Waiting for nslookup..."
      sleep 10s
      cmd=`nslookup ${mgs_fqdn_hostname_nic1} | grep -qi "Name:"`
    done
#fi



mgs_ip=`nslookup ${mgs_fqdn_hostname_nic1} | grep "Address: " | gawk '{ print $2 }'` ; echo $mgs_ip
if [ -z $mgs_ip ]; then

  # Add logic to ensure the below is not empty
    cmd=`nslookup ${mgs_fqdn_hostname_nic0} | grep -qi "Name:"`
    while [ $? -ne 0 ];
    do
      echo "Waiting for nslookup..."
      sleep 10s
      cmd=`nslookup ${mgs_fqdn_hostname_nic0} | grep -qi "Name:"`
    done

  mgs_ip=`nslookup ${mgs_fqdn_hostname_nic0} | grep "Address: " | gawk '{ print $2 }'` ; echo $mgs_ip
fi


#mgs_ip=`nslookup ${mgs_fqdn_hostname_nic1} | grep "Address: " | gawk '{ print $2 }'` ; echo $mgs_ip
#if [ -z $mgs_ip ]; then
#  mgs_ip=`nslookup ${mgs_fqdn_hostname_nic0} | grep "Address: " | gawk '{ print $2 }'` ; echo $mgs_ip
#fi

#mgs_ip=`nslookup ${mgs_hostname_prefix}1 | grep "Address: " | gawk '{ print $2 }'` ; echo $mgs_ip
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
  index=$((((((num-1))*total_disk_count))+(dcount)))
  echo $index
  dcount=$((dcount+1)) 
  if [ $enable_mdt_raid0 = "true" -a $total_disk_count -gt 1 ]; then
    echo "wait to loop through all disk"
  else
    disk_mount
  fi

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

  index=$((((((num-1))*total_disk_count))+(dcount)))
  echo $index  
  drive_letter=`echo $disk | sed 's/sd//'`
  drive_variables="${drive_variables}${drive_letter}"
  dcount=$((dcount+1))
  if [ $enable_mdt_raid0 = "true" -a $total_disk_count -gt 1 ]; then
    echo "wait to loop through all disk"
  else
    disk_mount
  fi
done;

echo "$dcount $disk_type disk found"

if [ $enable_mdt_raid0 = "true" -a $total_disk_count -gt 1 ]; then
  disk_mount
fi


service lustre status
lctl list_nids
nids=`lctl list_nids` | grep tcp1
echo $nids

df -h


# Update lnet service to start with correct config and enable at boot time
lnet_service_config="/usr/lib/systemd/system/lnet.service"
cp $lnet_service_config $lnet_service_config.backup
search_string="ExecStart=/usr/sbin/lnetctl import /etc/lnet.conf"
nic_add="ExecStart=/usr/sbin/lnetctl net add --net tcp1 --if $interface  –peer-timeout 180 –peer-credits 128 –credits 1024"

sed -i "s|$search_string|#$search_string\n$nic_add|g" $lnet_service_config
# To comment ConditionPathExists clause
sed -i "s|ConditionPathExists=!/proc/sys/lnet/|#ConditionPathExists=!/proc/sys/lnet/|g" $lnet_service_config

systemctl status lnet
systemctl enable lnet

echo "setup complete"
set +x


