#!/bin/bash

set -x

echo "Running studentvm.sh script for $vmname (logging in studentvm.log)"

exec >/root/studentvm.log 2>&1 

vmname="$1"  # should be something like t01-vm01

echo "Running studentvm.sh script for $vmname"

vmnumber="${vmname#*vm}"  # now just 01

case "$vmnumber" in
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

# wait for networking to stabilize
for i in $(seq 1 10); do
    [[ "$(echo | nc 192.168.100.1 22)" == *SSH* ]] && break
    sleep 5
done

# if no networking, give up:
[[ "$(echo | nc 192.168.100.1 22)" == *SSH* ]] || exit 255

configure_manual_vms()
{
    yum install -y wget git lsof

    ## Installing openvz by following the instructions from here:
    ##    https://wiki.openvz.org/Vzstats
    ##

    wget -P /etc/yum.repos.d/ https://download.openvz.org/openvz.repo

    rpm --import http://download.openvz.org/RPM-GPG-Key-OpenVZ

    yum install -y vzkernel

    ## these values will be replaced by the stuff below
    sed -i 's,net.ipv4.ip_forward,### net.ipv4.ip_forward,' /etc/sysctl.conf
    sed -i 's,kernel.sysrq,### kernel.sysrq,' /etc/sysctl.conf

    cat >>/etc/sysctl.conf <<EEE
# On Hardware Node we generally need
# packet forwarding enabled and proxy arp disabled
net.ipv4.ip_forward = 1
net.ipv6.conf.default.forwarding = 1
net.ipv6.conf.all.forwarding = 1
net.ipv4.conf.default.proxy_arp = 0

# Enables source route verification
net.ipv4.conf.all.rp_filter = 1

# Enables the magic-sysrq key
kernel.sysrq = 1

# We do not want all our interfaces to send redirects
net.ipv4.conf.default.send_redirects = 1
net.ipv4.conf.all.send_redirects = 0
EEE

    echo "SELINUX=disabled" > /etc/sysconfig/selinux

    yum install -y vzctl vzquota ploop

    (
	set -e
	cd /vz/template/cache
	wget http://192.168.100.1:28080/downloads/centos-6-x86_64-minimal.tar.gz
    ) || exit 255
}

configure_wakame_vms()
{
    echo TODO-configure_wakame_vms
}

set_hostname()
{
    hostname "$1"
    sed -i "s,HOSTNAME=.*,HOSTNAME=$1.localdomain," /etc/sysconfig/network
    echo 127.0.0.1 $1 >>/etc/hosts
}

set -e

case "$vmnumber" in
    # manual{1,2} VMs:
    01 | 02)
	configure_manual_vms
	set_hostname manual${vmnumber#0}
	;;
    03 | 04)
	configure_wakame_vms
	set_hostname manual${vmnumber#0}
	;;
    *)
	echo bug
	;;
esac

# assume configuration was OK
# turn off configuration boot script
echo 'exit' >do-first.sh

#end of script#  # <<-minimal check to make sure whole script was downloaded
