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


mkdir -p /root/.ssh
chmod 700 /root/.ssh
# from vmwgkey.pub
cat >/root/.ssh/authorized_keys <<EOF
ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDk+Y8KrCFZaGJdstRvqrmvB7ZYvSRP0vMQsMovnDRsbKlzoG7IgtreLFPDoCklHj2hsFszUlgsIB/2+zDDX2nk4sSiLXABMfzkaMZl0O7Bvq//1ULMWsQw/uuIP7ocxIAsqoxrlnmbEcP1GE1rU0cgGOOkoEyeZe/3WQ2iw7qA8wnMDzFHIHvIUO4BNW5RUyv/9E6WioG+vFRq11+AvcJu9NV3yHFzRn5H9JipeCU9WObP9c8YYlsCG1e+IdiWZAbKUizPg6tRzhkvUHZc3id2Sy4uGnt4rH8pLtQFt/u5ZrtXMJ7jML9n7Tw55pScWeAyzKVW/bxu4GBjifqFomF5 knoppix@Microknoppix
EOF
chmod 644 /root/.ssh/authorized_keys

useradd centos

# make gateway pw different so users do not log in accidentally
echo "notcentos" | passwd centos --stdin

(
    cd /root
    tar czvf /tmp/s.tar.gz .ssh
    cd /home/centos
    tar xzvf /tmp/s.tar.gz
    chown centos:centos .ssh
)

echo "centos ALL=(ALL) NOPASSWD: ALL" >>/etc/sudoers

# turn off configuration boot script
mkdir -p /root/hide
mv /root/poll-for-vm-auto-conf.sh /root/hide 2>/dev/null || true

#end of script#  # <<-minimal check to make sure whole script was downloaded
