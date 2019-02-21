#/bin/bash
set -x 

uname -a
getenforce
modprobe lnet
lnetctl lnet configure 
lnetctl net show
lnetctl net add --net tcp1 --if ens3
lnetctl net show --net tcp > tcp.yaml
lnetctl  import --del tcp.yaml
lctl list_nids

mds_ip=`nslookup lustre-mds-server-1.public2.sasvcn.oraclevcn.com | grep "Address: " | gawk '{ print $2 }'` ; echo $mds_ip
mount -t lustre ${mds_ip}@tcp1:/lustrefs /mnt

df -h 


echo "complete"
set +x 
