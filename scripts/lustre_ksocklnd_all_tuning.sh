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

