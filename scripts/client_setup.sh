#/bin/bash
set -x 

mgs_fqdn_hostname_nic0=$1
mgs_fqdn_hostname_nic1=$2
sas_workload=$3

source /tmp/env_variables.sh

# ensure the change before reboot is effective (should be unlimited)
ulimit -l 
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
  interface="ens3"
else
  # TODO - Add logic to use nic_100gbps RDMA first if its configured already.  Look for ethernet interface with name:  enp94s0f0.  
  # This interface should be used instead of eno2, if its already setup for RMDA cluster
  # For compute instances having nic_25gbps ethernet bandwidth speed 
  ifconfig | grep "eno2: "
  if [ $? -eq 0 ]; then
    echo "Found nic_25gbps network interface";
    nic_25gbps=true
    interface="eno2"
  else
    echo "Expected network inferface missing, abort deployment";
    exit 1;
  fi
fi
lnetctl net add --net tcp1 --if $interface  –peer-timeout 180 –peer-credits 128 –credits 1024


lnetctl net show --net tcp > tcp.yaml
lnetctl  import --del tcp.yaml
lctl list_nids

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
#   mgs_ip=`nslookup ${mgs_fqdn_hostname_nic0} | grep "Address: " | gawk '{ print $2 }'` ; echo $mgs_ip
#fi

#mds_ip=`nslookup lustre-mds-server-1 | grep "Address: " | gawk '{ print $2 }'` ; echo $mds_ip
disk_type=nvme
fsname=lfsnvme
mount_point="/mnt/mdt_$disk_type"
mkdir -p $mount_point
# -o flock recommended for SAS workloads. 
#if [ $sas_workload -eq 1 ]; then 
#  mount_options=" -o flock "
#fi
 
mount -t lustre -o flock ${mgs_ip}@tcp1:/$fsname $mount_point
if [ $? -eq 0 ]; then
  ## Update fstab
  cp /etc/fstab /etc/fstab.backup
  echo "${mgs_ip}@tcp1:/$fsname  $mount_point lustre defaults,_netdev,flock,x-systemd.automount,x-systemd.requires=lnet.service 0 0" >> /etc/fstab
fi

disk_type=bv
fsname=lfsbv
mount_point="/mnt/mdt_$disk_type"
mkdir -p $mount_point
mount -t lustre -o flock ${mgs_ip}@tcp1:/$fsname $mount_point
if [ $? -eq 0 ]; then
  ## Update fstab
  cp /etc/fstab /etc/fstab.backup
  echo "${mgs_ip}@tcp1:/$fsname  $mount_point lustre defaults,_netdev,flock,x-systemd.automount,x-systemd.requires=lnet.service 0 0" >> /etc/fstab
fi



df -h 


sudo chown -R opc:opc /mnt/mdt_*



# Update lnet service to start with correct config and enable at boot time
lnet_service_config="/usr/lib/systemd/system/lnet.service"
cp $lnet_service_config $lnet_service_config.backup
search_string="ExecStart=/usr/sbin/lnetctl import /etc/lnet.conf"

nic_add="ExecStart=/usr/sbin/lnetctl net add --net tcp1 --if $interface  –peer-timeout 180 –peer-credits 128 –credits 1024"


sed -i "s|$search_string|#$search_string\n$nic_add|g" $lnet_service_config
# To comment ConditionPathExists clause
sed -i "s|ConditionPathExists=!/proc/sys/lnet/|#ConditionPathExists=!/proc/sys/lnet/|g" $lnet_service_config

#systemctl daemon-reload
#systemctl restart lnet 
systemctl status lnet
systemctl enable lnet



echo "complete"
set +x 
