#!/bin/bash

set -x 

# based on LUG2019-Systemadmin-tutorial.pdf
# do this in cloud-init
#echo "options lnet check_routers_before_use=1 router_ping_timeout=120 dead_router_check_interval=50 avoid_asym_router_failure=0 live_router_check_interval=50" > /etc/modprobe.d/lnet.conf


# /etc/lnet.conf  - no such static file used in my deployment,  it gets generated on the fly using the lctl command in remote-exec. *_setup.sh files. 

# https://lustre.ornl.gov/lustre101-courses/content/C1/L5/LustreTuning.pdf
echo "63" > /sys/module/ksocklnd/parameters/peer_credits
echo "2560" > /sys/module/ksocklnd/parameters/credits
echo "100" > /sys/module/ksocklnd/parameters/sock_timeout


# Server , incl MDS
echo "options ksocklnd nscheds=10 sock_timeout=100 credits=2560 peer_credits=63 enable_irq_affinity=0"  >  /etc/modprobe.d/ksocklnd.conf

# clients - currently same values as above. 

should peer_credits be higher than 63?
tx_buffer_size=1073741824 rx_buffer_size=1073741824
clirent - defaults,flock,_netdev


[root@lustre-oss-server-nic0-4 ~]# lspci -vv | less

46:00.0 Ethernet controller: Broadcom Inc. and subsidiaries BCM57414 NetXtreme-E 10Gb/25Gb RDMA Ethernet Controller
MaxPayload 256 bytes, MaxReadReq 512 bytes
46:00.1 Ethernet controller: Broadcom Inc. and subsidiaries BCM57414 NetXtreme-E 10Gb/25Gb RDMA Ethernet Controller (rev 01)
MaxPayload 256 bytes, MaxReadReq 512 bytes

[root@lustre-oss-server-nic0-4 ~]# lctl --net tcp1 conn_list
[root@lustre-oss-server-nic0-4 ~]# lctl --net tcp1 conn_list | grep client


TODO
We should have seperate values for server and clients
■/etc/modprobe.d/ksocklnd.conf Clients and Router Side
options ksocklnd peer_credits=16
options ksocklnd tx_buffer_size=0
options ksocklnd rx_buffer_size=65536
■/etc/modprobe.d/ksocklnd.conf Server Side
options ksocklnd peer_credits=32

