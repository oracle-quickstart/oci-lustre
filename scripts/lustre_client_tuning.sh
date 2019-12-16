#!/bin/bash

set -x 

echo "Lustre client tuning ..." 
# based on LUG2019-sysadmin-tuturial.pdf

lctl set_param debug="+neterror"


# https://cpb-us-e1.wpmucdn.com/blogs.rice.edu/dist/0/2327/files/2014/03/Fragalla.pdf
echo "before tuning" 
ethtool -k ens3 | grep checksum
ethtool -K ens3 rx off tx off
echo "after tuning"
ethtool -k ens3 | grep checksum

lctl set_param ldlm.namespaces.*.lru_size=2000
lctl set_param osc.*.checksums=0
lctl set_param timeout=600
#lctl set_param ldlm_timeout=200  - This fails with below error
#error: set_param: param_path 'ldlm_timeout': No such file or directory

lctl set_param ldlm_timeout=200
lctl set_param at_min=250
lctl set_param at_max=600

# For 4MB RPC, set the below
lctl set_param osc.*.max_rpcs_in_flight=256
lctl set_param osc.*.max_dirty_mb=2048


# http://doc.lustre.org/lustre_manual.xhtml see section 33.9.2
# This might fail, since after making the change on OSS for 16MB RPC, the client needs to be umount and remount for the below commmand to be successful or else you get "Numerical result out of range" error. 
###lctl set_param osc.lfsbv-OST*.max_pages_per_rpc=4096
# max_pages_per_rpc=256
# 256 * 4K page_size = 1024K = 1MB IO
# So for 16MB RPC,  make it
# max_pages_per_rpc=4096   (4096*4K=16MB)
# For 16MB RPC, set the below
lctl set_param osc.*.max_rpcs_in_flight=64
lctl set_param osc.*.max_dirty_mb=2040
# Cannot set to 2048, but I can set 2040 or 2047 also


# llite.fsname_instance.max_read_ahead_mb - Controls the maximum amount of data readahead on a file. Files are read ahead in RPC-sized chunks (4 MiB, or the size of the read() call, if larger) after the second sequential read on a file descriptor. Random reads are done at the size of the read() call only (no readahead). Reads to non-contiguous regions of the file reset the readahead algorithm, and readahead is not triggered until sequential reads take place again.
# This is the global limit for all files and cannot be larger than 1/2 of the client RAM. To disable readahead, set max_read_ahead_mb=0.

# llite.fsname_instance.max_read_ahead_per_file_mb - Controls the maximum number of megabytes (MiB) of data that should be prefetched by the client when sequential reads are detected on a file. This is the per-file readahead limit and cannot be larger than max_read_ahead_mb.

lctl set_param llite.*.max_read_ahead_mb=256
lctl set_param llite.*.max_read_ahead_per_file_mb=256


# http://wiki.lustre.org/images/e/e4/LUG-2010-tricksRev.pdf

