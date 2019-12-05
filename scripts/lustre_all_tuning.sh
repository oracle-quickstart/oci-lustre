#!/bin/bash

set -x 

##########
# VALIDATE WHICH CHANGES ARE APPLICABLE FOR YOUR INSTALL AND ONLY THEN MAKE CHANGES
#########

# based on LUG2019-Systemadmin-tutorial.pdf
# do this in cloud-init
#echo "options lnet check_routers_before_use=1 router_ping_timeout=120 dead_router_check_interval=50 avoid_asym_router_failure=0 live_router_check_interval=50" > /etc/modprobe.d/lnet.conf

# ko2iblnd is for infiniband and RDMA

# /etc/lnet.conf  - no such static file used in my deployment,  it gets generated on the fly using the lctl command in remote-exec. *_setup.sh files. 


# MTU for 2nd NIC was set to 1500 as part of mds/oss_setup.sh script already.  NIC0 are already using MTU=1500 
# To make change 
# ip link set dev eno3d1 mtu 9000
# For change to persist even after reboot,  make change here:  /etc/sysconfig/network-scripts/ifcfg-eno3d1.  Already did it via mds/oss_setup.sh script 
# Client nodes have 1 NIC only,  so they come pre-configured for MTU=1500. Validated on VM.Standard2.24

