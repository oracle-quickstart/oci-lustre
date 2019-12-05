#!/bin/bash 

set -x 


echo `hostname` | grep -qi "lustre-client-"
if [ $? -eq 0 ]; then

    #  configure 1st NIC
    ifconfig | grep "^eno2:"
    if [ $? -eq 0 ] ; then
      primaryNICInterface="eno2"
    fi
    ifconfig | grep "^ens3:"
    if [ $? -eq 0 ] ; then
      primaryNICInterface="ens3"
    fi

    ifconfig | grep "^enp70s0f0:"
    if [ $? -eq 0 ] ; then
      primaryNICInterface="enp70s0f0"
    fi
    ifconfig | grep "^eno1:"
    if [ $? -eq 0 ] ; then
      primaryNICInterface="eno1"
    fi


    # client nodes
    ip link set dev $primaryNICInterface mtu 9000 && ethtool -G $primaryNICInterface rx 2047 tx 2047 rx-jumbo 8191
    #Interrupt Coalesce
    # Several packets in a rapid sequence can be coalesced into one interrupt passed up to the CPU, providing more CPU time for application processing.
    # The below displays current settings,  DOES NOT MAKE any change
    ethtool -c $primaryNICInterface
else
    # server nodes
    ifconfig | grep "^eno3d1:\|^enp70s0f1d1:\|^eno2d1:"
    if [ $? -eq 0 ] ; then
      echo "2 NIC setup"
      ifconfig | grep "^enp70s0f1d1:"
      if [ $? -eq 0 ] ; then
        interface="enp70s0f1d1"
      fi
      ifconfig | grep "^eno3d1:"
      if [ $? -eq 0 ] ; then
        interface="eno3d1"
      fi
      # AMD BM.Standard.E2.64
      ifconfig | grep "^eno2d1:"
      if [ $? -eq 0 ] ; then
        interface="eno2d1"
      fi
    fi
    ip link set dev $interface mtu 9000 && ethtool -G $interface rx 2047 tx 2047 rx-jumbo 8191
    # Interrupt Coalesce
    # Several packets in a rapid sequence can be coalesced into one interrupt passed up to the CPU, providing more CPU time for application processing.
    ethtool -c $interface


    #  configure 1st NIC
    ifconfig | grep "^eno2:"
    if [ $? -eq 0 ] ; then
      primaryNICInterface="eno2"
    fi
    ifconfig | grep "^ens3:"
    if [ $? -eq 0 ] ; then
      primaryNICInterface="ens3"
    fi

    ifconfig | grep "^enp70s0f0:"
    if [ $? -eq 0 ] ; then
      primaryNICInterface="enp70s0f0"
    fi
    ifconfig | grep "^eno1:"
    if [ $? -eq 0 ] ; then
      primaryNICInterface="eno1"
    fi

    # Update ring parameters to max for NIC-0 on server nodes
    ethtool -G $primaryNICInterface rx 2047 tx 2047 rx-jumbo 8191
fi


