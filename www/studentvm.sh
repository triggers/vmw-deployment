#!/bin/bash

set -x

echo "Running studentvm.sh script for $vmname (logging in studentvm.log)"

exec >>/root/studentvm.log 2>&1 

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
    
    # host{1,2,3} VMs:
    05) ipsuffix=11 ;;
    06) ipsuffix=12 ;;
    07) ipsuffix=13 ;;
    
    *) exit 255 ;; # bug, give up
esac

eth1-is-instance-network-setup()
{
    subnet=192.168.4
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
IPADDR=${subnet}.$ipsuffix
NETMASK=255.255.255.0
GATEWAY=192.168.${subnet##*.}.1
EOF

    ifdown eth0
    ifdown eth1

    # ifup eth0  # leave this one down
    ifup eth1
}

eth0-is-instance-network-setup()
{
    subnet=192.168.5
    cat >/etc/sysconfig/network-scripts/ifcfg-eth0 <<EOF
DEVICE=eth0
TYPE=Ethernet
UUID=f7d6973b-1eb2-4ec1-85b4-9f8c3d50f1cc
ONBOOT=yes
NM_CONTROLLED=no
BOOTPROTO=static
IPADDR=${subnet}.$ipsuffix
NETMASK=255.255.255.0
GATEWAY=192.168.${subnet##*.}.1
EOF

    cat >/etc/sysconfig/network-scripts/ifcfg-eth1 <<EOF
DEVICE=eth1
TYPE=Ethernet
UUID=ad672589-bb38-4340-87da-2cde1afb9649
ONBOOT=no
NM_CONTROLLED=no
BOOTPROTO=static
IPADDR=172.16.5.99
NETMASK=255.255.255.0
EOF
    
    rm -f /etc/sysconfig/network-scripts/ifcfg-eth{2,3,4,5}
    rm -f /etc/sysconfig/network-scripts/ifcfg-eth*~
    
    ifdown eth0
    ifdown eth1

    ifup eth0
    # ifup eth1  # leave this one down
}

case "$vmnumber" in
    # manual{1,2} and wakame{1,2} VMs:
    01 | 02 | 03 | 04)
	eth1-is-instance-network-setup
	;;
    # host1 VM
    05)
	eth0-is-instance-network-setup
	sed -i 's/5.99/5.11/' /etc/sysconfig/network-scripts/ifcfg-eth1
	# special for host1: bring up eth1 after the reboot below
	sed -i 's/ONBOOT=no/ONBOOT=yes/' /etc/sysconfig/network-scripts/ifcfg-eth1
	;;
    # host{2,3} VMs
    06 | 07)
	eth0-is-instance-network-setup
	;;
    
    *) exit 255 ;; # bug, give up
esac

# wait for networking to stabilize
for i in $(seq 1 10); do
    [[ "$(echo | nc 192.168.100.1 22)" == *SSH* ]] && break
    sleep 5
done

# if no networking, give up:
[[ "$(echo | nc 192.168.100.1 22)" == *SSH* ]] || exit 255

chkconfig iptables off

mkdir -p /root/.ssh
chmod 700 /root/.ssh
# from vmwgkey.pub
cat >/root/.ssh/authorized_keys <<EOF
ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDk+Y8KrCFZaGJdstRvqrmvB7ZYvSRP0vMQsMovnDRsbKlzoG7IgtreLFPDoCklHj2hsFszUlgsIB/2+zDDX2nk4sSiLXABMfzkaMZl0O7Bvq//1ULMWsQw/uuIP7ocxIAsqoxrlnmbEcP1GE1rU0cgGOOkoEyeZe/3WQ2iw7qA8wnMDzFHIHvIUO4BNW5RUyv/9E6WioG+vFRq11+AvcJu9NV3yHFzRn5H9JipeCU9WObP9c8YYlsCG1e+IdiWZAbKUizPg6tRzhkvUHZc3id2Sy4uGnt4rH8pLtQFt/u5ZrtXMJ7jML9n7Tw55pScWeAyzKVW/bxu4GBjifqFomF5 knoppix@Microknoppix
EOF
chmod 644 /root/.ssh/authorized_keys

useradd centos
echo "centos${vmnumber#0}" | passwd centos --stdin

(
    cd /root
    tar czvf /tmp/s.tar.gz .ssh
    cd /home/centos
    tar xzvf /tmp/s.tar.gz
    chown centos:centos .ssh
)

echo "centos ALL=(ALL) NOPASSWD: ALL" >>/etc/sudoers

sed -i 's,keepcache=0,keepcache=1,' /etc/yum.conf

yum install -y wget git lsof nano

configure_manual_vms()
{
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

    (
	cd /home/centos
	curl 192.168.100.1:28080/downloads/ssh_key_pair.tar | tar xv
	chown -R centos:centos ssh_key_pair
    )
}

configure_wakame_vms_wo_images()
{
    (
	cd /
	curl 192.168.100.1:28080/downloads/var-cache-yum.tar | tar xv

	cd /home/centos
	curl 192.168.100.1:28080/downloads/ssh_key_pair.tar | tar xv
	chown -R centos:centos ssh_key_pair
    )
}

configure_wakame_vms()
{
    (
	cd /
	curl 192.168.100.1:28080/downloads/var-cache-yum.tar | tar xv
	cd /home/centos
	curl 192.168.100.1:28080/downloads/stuff_to_prepare.tar | tar xv

	mv stuff_to_prepare/images .
	chown -R centos:centos images

	mv stuff_to_prepare/ssh_key_pair .
	chown -R centos:centos ssh_key_pair

	rmdir stuff_to_prepare
    )
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
	set_hostname wakame$(( 10#$vmnumber - 2 ))
	;;
    05)
	configure_wakame_vms_wo_images
	set_hostname host$(( 10#$vmnumber - 4 ))
	;;
    06 | 07)
	configure_wakame_vms
	set_hostname host$(( 10#$vmnumber - 4 ))
	;;
    *)
	echo bug
	;;
esac

# assume configuration was OK
# turn off configuration boot script

## echo 'exit' >do-first.sh  ## does not work because launched in subprocess
# so
mkdir -p /root/hide
mv /root/poll-for-vm-auto-conf.sh /root/hide 2>/dev/null || true

reboot

#end of script#  # <<-minimal check to make sure whole script was downloaded
