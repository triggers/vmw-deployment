#!/bin/bash

vmname="$1"  # should be something like gw01

echo "Running gw.sh script for $vmname"

justdigits="${vmname//[^0-9]/}"
ipsuffix=$(( $justdigits + 10 ))
if [ "$ipsuffix" -lt "1" ] || [ "$ipsuffix" -gt "254" ]; then
    echo "Generated suffix ($ipsuffix) invalid" 1>&2
    ipsuffix=99
fi


cat >/etc/sysconfig/network-scripts/ifcfg-eth0 <<EOF
DEVICE=eth0
TYPE=Ethernet
UUID=ad672589-bb38-4340-87da-2cde1afb9649
ONBOOT=yes
NM_CONTROLLED=no
BOOTPROTO=static
IPADDR=192.168.100.$ipsuffix
NETMASK=255.255.255.0
GATEWAY=192.168.100.1
EOF

cat >/etc/sysconfig/network-scripts/ifcfg-eth1 <<EOF
DEVICE=eth1
TYPE=Ethernet
UUID=f7d6973b-1eb2-4ec1-85b4-9f8c3d50f1cc
ONBOOT=yes
NM_CONTROLLED=no
BOOTPROTO=static
IPADDR=192.168.4.1
NETMASK=255.255.255.0
EOF

ifdown eth0
ifdown eth1

ifup eth0
ifup eth1

/etc/init.d/iptables stop
/sbin/iptables -t nat -A POSTROUTING -o eth0 -j SNAT --to 192.168.100.$ipsuffix
echo 1 > /proc/sys/net/ipv4/ip_forward
echo 1 > /proc/sys/net/ipv4/conf/eth0/proxy_arp

#end of script#  # <<-minimal check to make sure whole script was downloaded
