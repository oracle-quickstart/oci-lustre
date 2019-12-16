#!/bin/bash
set -x 


#echo "net.ipv4.tcp_window_scaling=1" >> /etc/sysctl.conf        
#echo "net.ipv4.tcp_timestamps=1" >> /etc/sysctl.conf
#echo "net.ipv4.tcp_sack=1" >> /etc/sysctl.conf
#echo "net.ipv4.tcp_wmem=4096 4224000 2147483647" >> /etc/sysctl.conf    
#echo "net.ipv4.tcp_rmem=4096 4224000 2147483647" >> /etc/sysctl.conf
#echo "net.ipv4.tcp_reordering=3" >> /etc/sysctl.conf
#echo "net.ipv4.tcp_mem=2147483647 2147483647 2147483647" >> /etc/sysctl.conf
#echo "net.ipv4.tcp_low_latency=1" >> /etc/sysctl.conf   
#echo "net.ipv4.tcp_adv_win_scale=2" >> /etc/sysctl.conf 
#echo "net.ipv4.neigh.default.gc_interval=2000000" >> /etc/sysctl.conf
#echo "net.ipv4.neigh.ens3.gc_stale_time=2000000" >> /etc/sysctl.conf
#echo "net.ipv4.neigh.default.gc_thresh3=32768" >> /etc/sysctl.conf
#echo "net.ipv4.neigh.default.gc_thresh2=32000" >> /etc/sysctl.conf
#echo "net.ipv4.neigh.default.gc_thresh1=30000" >> /etc/sysctl.conf
#echo "net.ipv4.neigh.ens3.ucast_solicit=9" >> /etc/sysctl.conf
#echo "net.ipv4.neigh.ens3.mcast_solicit=9" >> /etc/sysctl.conf
#echo "net.ipv4.conf.all.arp_ignore=1" >> /etc/sysctl.conf
#echo "net.ipv4.conf.all.arp_filter=1    " >> /etc/sysctl.conf
 echo "net.core.wmem_max=16777216" >> /etc/sysctl.conf
 echo "net.core.rmem_max=16777216" >> /etc/sysctl.conf
 echo "net.core.wmem_default=16777216" >> /etc/sysctl.conf
 echo "net.core.rmem_default=16777216" >> /etc/sysctl.conf
 echo "net.core.optmem_max=16777216" >> /etc/sysctl.conf
 echo "net.core.netdev_max_backlog=27000" >> /etc/sysctl.conf   
 echo "kernel.sysrq=1" >> /etc/sysctl.conf


echo "kernel.shmmax=18446744073692774399" >> /etc/sysctl.conf 
echo "net.core.somaxconn=8192" >> /etc/sysctl.conf
echo "net.ipv4.tcp_adv_win_scale=2" >> /etc/sysctl.conf
echo "net.ipv4.tcp_low_latency=1" >> /etc/sysctl.conf

echo "net.ipv4.tcp_rmem = 212992 87380 16777216" >> /etc/sysctl.conf
echo "net.ipv4.tcp_sack = 1" >> /etc/sysctl.conf
<<<<<<< HEAD
=======
echo "net.ipv4.tcp_timestamps = 1" >> /etc/sysctl.conf
>>>>>>> 7dcc85c22cc793cc0d8f0481f827a955f5537c61
echo "net.ipv4.tcp_window_scaling = 1" >> /etc/sysctl.conf
echo "net.ipv4.tcp_wmem = 212992 65536 16777216" >> /etc/sysctl.conf
echo "vm.min_free_kbytes = 65536" >> /etc/sysctl.conf

# https://lustre.ornl.gov/lustre101-courses/content/C1/L5/LustreTuning.pdf
# As per Lustre reccomendation from google searches
#net.ipv4.tcp_no_metrics_save = 0 (already set)
echo "net.ipv4.tcp_no_metrics_save = 0" >> /etc/sysctl.conf
#net.ipv4.tcp_window_scaling = 1  (already set)
echo "net.ipv4.tcp_congestion_control = cubic" >> /etc/sysctl.conf
echo "net.ipv4.tcp_timestamps = 0" >> /etc/sysctl.conf
#net.ipv4.tcp_sack = 1  (already set)

# https://lustre.ornl.gov/ecosystem-2016/documents/topics/Caldwell-ORNL-EthernetVsInfiniband.pdf
echo "net.ipv4.tcp_congestion_control = htcp" >> /etc/sysctl.conf


<<<<<<< HEAD
# echo 30000 > /proc/sys/net/core/netdev_max_backlog
# ifconfig eth1 txqueuelen ${TXQLEN:-40}


=======
>>>>>>> 7dcc85c22cc793cc0d8f0481f827a955f5537c61
/sbin/sysctl -p /etc/sysctl.conf

