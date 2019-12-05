#!/bin/sh
#
# Simple wrapper script for LNET Selftest
#

# Parameters are supplied as environment variables
# The defaults are reasonable for quick verification.
# For in-depth benchmarking, increase the time (TM)
# variable to e.g. 60 seconds, and iterate over
# concurrency to find optimal values.
#
# Reference: http://wiki.lustre.org/LNET_Selftest

# Concurrency
CN=${CN:-32}
#Size
SZ=${SZ:-1M}
# Length of time to run test (secs)
TM=${TM:-10}
# Which BRW test to run (read or write)
BRW=${BRW:-"read"}
# Checksum calculation (simple or full)
CKSUM=${CKSUM:-"simple"}

# The LST "from" list -- e.g. Lustre clients. Space separated list of NIDs.
# LFROM="10.10.2.21@tcp"
LFROM=${LFROM:?ERROR: the LFROM variable is not set}
# The LST "to" list -- e.g. Lustre servers. Space separated list of NIDs.
# LTO="10.10.2.22@tcp"
LTO=${LTO:?ERROR: the LTO variable is not set}

### End of customisation.

export LST_SESSION=$$
echo LST_SESSION = ${LST_SESSION}
lst new_session lst${BRW}
lst add_group lfrom ${LFROM}
lst add_group lto ${LTO}
lst add_batch bulk_${BRW}
lst add_test --batch bulk_${BRW} --from lfrom --to lto brw ${BRW} \
  --concurrency=${CN} check=${CKSUM} size=${SZ}
lst run bulk_${BRW}
echo -n "Capturing statistics for ${TM} secs "
lst stat lfrom lto &
LSTPID=$!
# Delay loop with interval markers displayed every 5 secs.
# Test time is rounded up to the nearest 5 seconds.
i=1
j=$((${TM}/5))
if [ $((${TM}%5)) -ne 0 ]; then let j++; fi
while [ $i -le $j ]; do
  sleep 5
  let i++
done
kill ${LSTPID} && wait ${LISTPID} >/dev/null 2>&1
echo
lst show_error lfrom lto
lst stop bulk_${BRW}
lst end_session
