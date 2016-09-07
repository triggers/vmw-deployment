#!/bin/bash

vmname="$1"  # should be something like t01-vm01

echo "Running gw.sh script for $vmname"

ipsuffix="${vmname#*vm}"  # now just 01

case "$ipsuffix" in
    # manual{1,2} VMs:
    01) ipsuffix=11 ;;
    02) ipsuffix=12 ;;

    # wakame{1,2} VMs:
    03) ipsuffix=21 ;;
    04) ipsuffix=22 ;;
    
    *) ipsuffix=99 ;;
esac


cat >/etc/sysconfig/network-scripts/ifcfg-eth0 <<EOF
DEVICE=eth0
TYPE=Ethernet
UUID=ad672589-bb38-4340-87da-2cde1afb9649
ONBOOT=no
NM_CONTROLLED=no
BOOTPROTO=static
IPADDR=192.168.99.99
NETMASK=255.255.255.0
EOF

cat >/etc/sysconfig/network-scripts/ifcfg-eth1 <<EOF
DEVICE=eth1
TYPE=Ethernet
UUID=f7d6973b-1eb2-4ec1-85b4-9f8c3d50f1cc
ONBOOT=yes
NM_CONTROLLED=no
BOOTPROTO=static
IPADDR=192.168.4.$ipsuffix
NETMASK=255.255.255.0
GATEWAY=192.168.4.1
EOF

ifdown eth0
ifdown eth1

# ifup eth0  # leave this one down
ifup eth1

#end of script#  # <<-minimal check to make sure whole script was downloaded
