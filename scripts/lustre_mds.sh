# #!/bin/bash
## cloud-init bootstrap script

set -x 

echo "mds_dual_nics=\"${mds_dual_nics}\"" >> /tmp/env_variables.sh
echo "oss_dual_nics=\"${oss_dual_nics}\"" >> /tmp/env_variables.sh
echo "mgs_hostname_prefix_nic0=\"${mgs_hostname_prefix_nic0}\"" >> /tmp/env_variables.sh
echo "mgs_hostname_prefix_nic1=\"${mgs_hostname_prefix_nic1}\"" >> /tmp/env_variables.sh
echo "PublicSubnetsFQDN=\"${PublicSubnetsFQDN}\"" >> /tmp/env_variables.sh
echo "PublicBSubnetsFQDN=\"${PublicBSubnetsFQDN}\"" >> /tmp/env_variables.sh



## Stop SSHD to prevent remote execution during this process
systemctl stop sshd

THIS_FQDN=`hostname --fqdn`
THIS_HOST=${THIS_FQDN%%.*}

#######################################################"
################# Turn Off the Firewall ###############"
#######################################################"
echo "Turning off the Firewall..."
which apt-get &> /dev/null
if [ $? -eq 0 ] ; then
    echo "" > /etc/iptables/rules.v4
    echo "" > /etc/iptables/rules.v6

    iptables -F
    iptables -X
    iptables -t nat -F
    iptables -t nat -X
    iptables -t mangle -F
    iptables -t mangle -X
    iptables -P INPUT ACCEPT
    iptables -P OUTPUT ACCEPT
    iptables -P FORWARD ACCEPT
else
    service firewalld stop
    chkconfig firewalld off
fi


#######################################################"
#################   Update resolv.conf  ###############"
#######################################################"
## Modify resolv.conf to ensure DNS lookups work from one private subnet to another subnet
cp /etc/resolv.conf /etc/resolv.conf.backup
rm -f /etc/resolv.conf
# echo "search ${PrivateBSubnetsFQDN} ${PrivateSubnetsFQDN} " > /etc/resolv.conf
echo "search ${PublicBSubnetsFQDN} ${PublicSubnetsFQDN} " > /etc/resolv.conf
echo "nameserver 169.254.169.254" >> /etc/resolv.conf


#######################################################"
#######################################################"



which apt-get &> /dev/null
if [ $? -eq 0 ] ; then
    echo "apt-get Ubuntu EL"
else
    echo "yum EL" 
fi

cat > /etc/yum.repos.d/lustre.repo << EOF
[hpddLustreserver]
name=CentOS- - Lustre
baseurl=https://downloads.whamcloud.com/public/lustre/latest-release/el7/server/
gpgcheck=0

[e2fsprogs]
name=CentOS- - Ldiskfs
baseurl=https://downloads.whamcloud.com/public/e2fsprogs/latest/el7/
gpgcheck=0

[hpddLustreclient]
name=CentOS- - Lustre
baseurl=https://downloads.whamcloud.com/public/lustre/latest-release/el7/client/
gpgcheck=0
EOF

cat > /tmp/lustre.repo << EOF
[hpddLustreserver]
name=CentOS-$releasever - Lustre
baseurl=https://downloads.whamcloud.com/public/lustre/lustre-2.10.6/el7/server/
gpgcheck=0

[e2fsprogs]
name=CentOS-$releasever - Ldiskfs
baseurl=https://downloads.whamcloud.com/public/e2fsprogs/1.44.3.wc1/el7/
gpgcheck=0

[hpddLustreclient]
name=CentOS-$releasever - Lustre
baseurl=https://downloads.whamcloud.com/public/lustre/lustre-2.10.6/el7/client/
gpgcheck=0
EOF

sudo yum install lustre-tests -y
if [ $? -ne 0 ]; then
  echo "yum install of lustre binaries failed"
  exit 1
fi

cp /etc/selinux/config /etc/selinux/config.backup
sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config

setenforce 0

echo "options ksocklnd nscheds=10 sock_timeout=100 credits=2560 peer_credits=63 enable_irq_affinity=0"  >  /etc/modprobe.d/ksocklnd.conf


cat /etc/os-release | grep "^NAME=" | grep "CentOS"
if [ $? -eq 0 ]; then
  awk -F\' /^menuentry/{print\$2}  /boot/efi/EFI/centos/grub.cfg
else
  os_with_lustre=`awk -F\' /^menuentry/{print\$2}  /boot/efi/EFI/redhat/grub.cfg  | grep -v "Rescue" | grep "lustre.x86_64" | gawk -F"'" ' { print $2 } ' `  ;  echo $os_with_lustre
  # Add single quotes
  os_with_lustre_with_quote="'${os_with_lustre}'"  ;  echo $os_with_lustre_with_quote
  grub2-set-default "'${os_with_lustre_with_quote}'"
fi



touch /tmp/complete
echo "complete.  rebooting now"
reboot 
set +x 
