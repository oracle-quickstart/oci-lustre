#!/bin/bash

set -x 
###########################
### OS Performance tuning
###########################

# The below applies for both compute and server nodes (storage)
cd /usr/lib/tuned/
cp -r throughput-performance/ sas-performance

echo "#
# tuned configuration
#
[main]
include=throughput-performance
summary=Broadly applicable tuning that provides excellent performance across a variety of common server workloads
[disk]
# The default unit for readahead is KiB.  This can be adjusted to sectors
# by specifying the relevant suffix, eg. (readahead => 8192 s). There must
# be at least one space between the number and suffix (if suffix is specified).
# assuming default 4096 was 4096 kb (4MB).  If 16MB is needed, then use readahead=>16384
devices=!dm-*, !sda1, !sda2, !sda3
readahead=>4096

[cpu]
force_latency=1
governor=performance
energy_perf_bias=performance
min_perf_pct=100
[vm]
transparent_huge_pages=never
[sysctl]
kernel.sched_min_granularity_ns = 10000000
kernel.sched_wakeup_granularity_ns = 15000000
vm.dirty_ratio = 30
vm.dirty_background_ratio = 10
vm.swappiness=30
" > sas-performance/tuned.conf

tuned-adm profile sas-performance

# Display active profile
tuned-adm active

cd -
<<<<<<< HEAD

# Values to try as per homeri page -  https://homerl.github.io/2016/04/06/Lustre-operations/
#vm.dirty_ratio = 10 #default 20
#vm.dirty_background_ratio = 5 #default 10
#vm.vfs_cache_pressure = 50 #default 100

#The default of 100 or relative "fair" is appropriate for compute servers. Set to lower than 100 for file servers on which the cache should be a priority. Set higher, maybe 500 to 1000, for interactive systems. Decreasing vfs_cache_pressure causes the kernel to prefer to retain dentry and inode caches

=======
>>>>>>> 7dcc85c22cc793cc0d8f0481f827a955f5537c61
