#/bin/bash

set -x

uname -a

sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config
getenforce
modprobe lnet
lnetctl lnet configure
lctl list_nids
lnetctl net add --net tcp1 --if ens3
mkfs.lustre --fsname=lustrefs --index=0   --mgs --mdt /dev/sdb
lctl network up
lctl list_nids
mkdir -p /mnt/mdt
mount -t lustre /dev/sdb /mnt/mdt

## Update fstab
echo "/dev/sdb               /mnt/mdt           lustre  defaults,_netdev        0 0" >> /etc/fstab

service lustre status
lctl list_nids
nids=`lctl list_nids` | grep tcp1
echo $nids

df -h

echo "setup complete"
set +x


