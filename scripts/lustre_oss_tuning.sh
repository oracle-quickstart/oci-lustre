#!/bin/bash

set -x 

# On the OSS the option readcache_max_filesize controls the maximum size of a file that both the read cache and writethrough cache will try to keep in memory. Files larger than readcache_max_filesize will not be kept in cache for either reads or writes. This was set to 2M on each OSS via the command
#lctl set_param osd-ldiskfs.*.readcache_max_filesize=2M
# We should allow much larger files to be cached.

# https://lustre.ornl.gov/lustre101-courses/content/C1/L5/LustreTuning.pdf
lctl set_param osd-ldiskfs.*.read_cache_enable=1
lctl set_param osd-ldiskfs.*.writethrough_cache_enable=1

# http://doc.lustre.org/lustre_manual.xhtml
<<<<<<< HEAD
lctl set_param obdfilter.lfsbv-*.brw_size=16
=======
###lctl set_param obdfilter.lfsbv-*.brw_size=16
>>>>>>> 7dcc85c22cc793cc0d8f0481f827a955f5537c61


