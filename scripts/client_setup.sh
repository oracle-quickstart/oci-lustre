#/bin/bash
set -x 

uname -a
getenforce
modprobe lnet
lnetctl lnet configure 
lnetctl net show
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
#lnetctl net add --net tcp1 --if ens3

lnetctl net show --net tcp > tcp.yaml
lnetctl  import --del tcp.yaml
lctl list_nids


mds_ip=`nslookup lustre-mds-server-1 | grep "Address: " | gawk '{ print $2 }'` ; echo $mds_ip
disk_type=nvme
fsname=lfsnvme
mount_point="/mnt/mdt_$disk_type"
mkdir -p $mount_point
mount -t lustre ${mds_ip}@tcp1:/$fsname $mount_point
if [ $? -eq 0 ]; then
  ## Update fstab
  cp /etc/fstab /etc/fstab.backup
  echo "${mds_ip}@tcp1:/$fsname  $mount_point lustre defaults,_netdev,noauto,x-systemd.automount,x-systemd.requires=lnet.service 0 0" >> /etc/fstab
fi

disk_type=bv
fsname=lfsbv
mount_point="/mnt/mdt_$disk_type"
mkdir -p $mount_point
mount -t lustre -o flock ${mds_ip}@tcp1:/$fsname $mount_point
if [ $? -eq 0 ]; then
  ## Update fstab
  cp /etc/fstab /etc/fstab.backup
  echo "${mds_ip}@tcp1:/$fsname  $mount_point lustre defaults,_netdev,x-systemd.automount,x-systemd.requires=lnet.service 0 0" >> /etc/fstab
fi



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

#systemctl daemon-reload
#systemctl restart lnet 
systemctl status lnet
systemctl enable lnet



echo "complete"
set +x 
