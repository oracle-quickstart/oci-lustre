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
