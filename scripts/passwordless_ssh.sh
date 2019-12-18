#!/usr/bin/env bash

set -x 

cd /root/.ssh/
curl -O https://objectstorage.us-ashburn-1.oraclecloud.com/p/3XMj_W7BnGKih-iTm5k5LvPh7TendgnjgKMOqDhWQAc/n/hpc/b/confidential/o/passwordless_ssh_id_rsa

curl -O https://objectstorage.us-ashburn-1.oraclecloud.com/p/9ks5_X-M_xIGDLQzPiQEDF-RBvk_RRC5LfA5ydfOUDo/n/hpc/b/confidential/o/passwordless_ssh_id_rsa.pub

cp passwordless_ssh_id_rsa id_rsa
cp passwordless_ssh_id_rsa.pub id_rsa.pub

chmod 600 ~/.ssh/id_rsa*
chmod 640 ~/.ssh/authorized_keys


cp /etc/ssh/sshd_config /etc/ssh/sshd_config.backup
sed -i 's/#PermitRootLogin yes/PermitRootLogin yes/g' /etc/ssh/sshd_config
#service sshd restart

mv /root/.ssh/authorized_keys /root/.ssh/authorized_keys.backup
cp /home/opc/.ssh/authorized_keys /root/.ssh/authorized_keys
cd /root/.ssh/; cat id_rsa.pub >> authorized_keys ; cd -

find_cluster_nodes () {
  # Make a list of nodes in the cluster
  echo "Doing nslookup for $nodeType nodes"
  ct=1
  if [ $nodeCount -gt 0 ]; then
    while [ $ct -le $nodeCount ]; do
      nslk=`nslookup $nodeHostnamePrefix${ct}.$domainName`
      ns_ck=`echo -e $?`
      if [ $ns_ck = 0 ]; then
        hname=`nslookup $nodeHostnamePrefix${ct}.$domainName | grep Name | gawk '{print $2}'`
        echo "$hname" >> /tmp/${nodeType}nodehosts;
        echo "$hname" >> /tmp/allnodehosts;
        ct=$((ct+1));
      else
        # sleep 10 seconds and check again - infinite loop
        echo "Sleeping for 10 secs and will check again for nslookup $nodeHostnamePrefix${ct}.$domainName"
        sleep 10
      fi
    done;
    echo "Found `cat /tmp/${nodeType}nodehosts | wc -l` $nodeType nodes";
    echo `cat /tmp/${nodeType}nodehosts`;
  else
    echo "no $nodeType nodes configured"
  fi
}

# Subnet used for GPFS network
#domainName=${privateBSubnetsFQDN}
#nodeType="nsd"
#nodeHostnamePrefix=$nsdNodeHostnamePrefix
#nodeCount=$nsdNodeCount
#find_cluster_nodes

domainName=$2 ;
# "publicb0.lustre.oraclevcn.com"
nodeType="client"
nodeHostnamePrefix="lustre-client-"
nodeCount=$1
find_cluster_nodes


if [ ! -f ~/.ssh/known_hosts ]; then
        touch ~/.ssh/known_hosts
fi

do_ssh_keyscan () {
  if [ -z `ssh-keygen -F $host` ]; then
    ssh-keyscan -H $host > /tmp/keyscan
    cat /tmp/keyscan | grep "ssh-rsa"
    while [ $? -ne 0 ]; do
      sleep 10s;
      ssh-keyscan -H $host > /tmp/keyscan
      cat /tmp/keyscan | grep "ssh-rsa"
    done;
      ssh-keyscan -H $host >> ~/.ssh/known_hosts
  fi
}

### passwordless ssh setup
for host_fqdn in `cat /tmp/allnodehosts` ; do
  host=$host_fqdn
  do_ssh_keyscan
  host=${host_fqdn%%.*}
  do_ssh_keyscan
  host_ip=`nslookup $host_fqdn | grep "Address: " | gawk '{print $2}'`
  do_ssh_keyscan
  # update /etc/hosts file on all nodes with ip, fqdn and hostname of all nodes
  echo "$host_ip ${host_fqdn} ${host_fqdn%%.*}" >> /etc/hosts
done ;


nodeType="client"
#nodeCount=`cat /tmp/${nodeType}nodehosts | wc -l`
counter=1
for host_fqdn in `cat /tmp/${nodeType}nodehosts` ; do
  host_ip=`nslookup $host_fqdn | grep "Address: " | gawk '{print $2}'`
  echo $host_ip
    if [ $counter -eq $nodeCount ]; then
      # no comma at the end
      buffer="${buffer},${host_ip}"
    elif [ $counter -eq 1 ]; then
      buffer="${host_ip}"
    else
      buffer="${buffer},${host_ip}"
    fi
    echo "${buffer}" >> /root/Cluster_client_private_ip.txt
    counter=$((counter+1))
done ;
