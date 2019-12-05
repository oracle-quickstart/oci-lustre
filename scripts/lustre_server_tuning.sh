#!/bin/bash
set -x
echo "Lustre server tuning ..."


for disk in `ls /dev/sd* | grep -v "\/dev\/sda" | grep -v "[0-9]$" | sed  "s|/dev/||g" ` ; do echo $disk ;
echo "queue/max_hw_sectors_kb";
cat /sys/block/$disk/queue/max_hw_sectors_kb ;
echo "queue/max_sectors_kb";
cat /sys/block/$disk/queue/max_sectors_kb ;
echo "queue/nr_requests";
cat /sys/block/$disk/queue/nr_requests ;
echo "queue/scheduler";
cat /sys/block/$disk/queue/scheduler ;
echo "queue/read_ahead_kb";
cat /sys/block/$disk/queue/read_ahead_kb ;
echo "device/queue_depth";
cat /sys/block/$disk/device/queue_depth ;
echo "device/timeout";
cat /sys/block/$disk/device/timeout ;
echo "queue/rq_affinity";
cat /sys/block/$disk/queue/rq_affinity;
done;

for disk in `ls /dev/sd* | grep -v "\/dev\/sda" | grep -v "[0-9]$" | sed  "s|/dev/||g" ` ; do echo $disk ;
echo `cat /sys/block/$disk/queue/max_hw_sectors_kb` > /sys/block/$disk/queue/max_sectors_kb ;
echo "192" > /sys/block/$disk/queue/nr_requests ;
echo "deadline" > /sys/block/$disk/queue/scheduler ;
echo "0" > /sys/block/$disk/queue/read_ahead_kb ;
echo "68" > /sys/block/$disk/device/timeout ;
done ;



# New changes based on tuning details from google search and other similar fs.
for disk in `ls /dev/sd* | grep -v "\/dev\/sda" | grep -v "[0-9]$" | sed  "s|/dev/||g" ` ; do echo $disk ;
echo "4096" > /sys/block/$disk/queue/max_sectors_kb ;
echo "256" > /sys/block/$disk/queue/nr_requests ;
echo "deadline" > /sys/block/$disk/queue/scheduler ;
echo "0" > /sys/block/$disk/queue/read_ahead_kb ;
echo "68" > /sys/block/$disk/device/timeout ;
echo "31" > /sys/block/$disk/device/queue_depth ; 
echo "2" > /sys/block/$disk/queue/rq_affinity ; 
done ;


# all servers
lctl set_param timeout=600
lctl set_param ldlm_timeout=200
lctl set_param at_min=250
lctl set_param at_max=600


# https://homerl.github.io/2016/04/06/Lustre-operations/
for disk in `ls /dev/sd* | grep -v "\/dev\/sda" | grep -v "[0-9]$" | sed  "s|/dev/||g" ` ; do echo $disk ;
echo "1024" > /sys/block/$disk/queue/nr_requests ;
echo "8192" > /sys/block/$disk/queue/read_ahead_kb ;
done ;


 
