#!/bin/bash

set -x 

echo "Lustre client tuning ..." 
# based on LUG2019-sysadmin-tuturial.pdf


lctl set_param osc.*.checksums=0
lctl set_param timeout=600
#lctl set_param ldlm_timeout=200  - This fails with below error 
#error: set_param: param_path 'ldlm_timeout': No such file or directory
lctl set_param ldlm_timeout=200
lctl set_param at_min=250
lctl set_param at_max=600
lctl set_param ldlm.namespaces.*.lru_size=128
lctl set_param osc.*.max_rpcs_in_flight=32
lctl set_param osc.*.max_dirty_mb=256
lctl set_param debug="+neterror"


# https://cpb-us-e1.wpmucdn.com/blogs.rice.edu/dist/0/2327/files/2014/03/Fragalla.pdf
echo "before tuning" 
ethtool -k ens3 | grep checksum
ethtool -K ens3 rx off tx off
echo "after tuning"
ethtool -k ens3 | grep checksum


lctl set_param ldlm.namespaces.*.lru_size=2000
lctl set_param osc.*.max_rpcs_in_flight=256
lctl set_param osc.*.max_dirty_mb=1024

# max_dirty_mb by default is set to 2000
lctl set_param ldlm.namespaces.*.lru_size=2000
lctl set_param osc.*.max_rpcs_in_flight=256
lctl set_param osc.*.max_dirty_mb=2000
lctl set_param osc.*.checksums=0
lctl set_param timeout=600
lctl set_param ldlm_timeout=200
lctl set_param at_min=250
lctl set_param at_max=600


# http://doc.lustre.org/lustre_manual.xhtml see section 33.9.2
# This might fail, since after making the change on OSS for 16MB RPC, the client needs to be umount and remount for the below commmand to be successful or else you get "Numerical result out of range" error. 
###lctl set_param osc.lfsbv-OST*.max_pages_per_rpc=4096

