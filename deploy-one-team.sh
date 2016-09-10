#!/bin/bash

# ROUGH PROTOTYPE, not generlized...

failed()
{
    echo  "Failed...exiting: $@" 1>&2
    exit 255
}

teamnumber="$1"

[[ "$teamnumber" == [0-9] ]] && teamnumber=0$teamnumber   # make the UI a little nicer
[[ "$teamnumber" == [0-9][0-9] ]] || failed "Parameter must be two digit team number"
    
eee='esxcli -s 192.168.1.219 -u root -d 1A:A8:3F:CE:AB:D1:31:11:0C:7A:CB:3C:1D:1E:2D:E8:72:DE:99:EC -p Wakame4Axsh'

ssh_vswitch_cmd() { ssh root@192.168.1.219 esxcli network vswitch standard "$@" ; }

# ssh_vswitch_cmd() { echo  "$@" ; }  # disable for now

false && for i in 1 2 3 4 5; do
    echo
    echo " --- $i ---"
    ssh_vswitch_cmd add -v t${teamnumber}-net${i}
    ssh_vswitch_cmd policy security set  -p true -v t${teamnumber}-net${i}
    ssh_vswitch_cmd portgroup add -p t${teamnumber}-net${i}-pg -v t${teamnumber}-net${i}
done

false && time ovftool --name="gw${teamnumber}" --datastore="ahd" \
     --net:"VM Network"="class-net-pg" --net:"pg1"="t${teamnumber}-net1-pg" \
     -dm=thin /root/ovftool/centos68-x86-autoconf16.ovf vi://root:Wakame4Axsh@192.168.1.219

# exit # STILL TESTING!

for i in 01 02; do
    time ovftool --name="t${teamnumber}-vm${i}" --datastore="ahd" \
	 --net:"VM Network"="t${teamnumber}-net2-pg" --net:"pg1"="t${teamnumber}-net1-pg" \
	 -dm=thin /root/ovftool/centos68-x86-autoconf16.ovf vi://root:Wakame4Axsh@192.168.1.219
done

false && for i in 03 04; do
    time ovftool --name="t${teamnumber}-vm${i}" --datastore="ahd" \
	 --net:"VM Network"="t${teamnumber}-net3-pg" --net:"pg1"="t${teamnumber}-net1-pg" \
	 -dm=thin /root/ovftool/centos68-x86-autoconf16.ovf vi://root:Wakame4Axsh@192.168.1.219
done

for i in 05 06 07; do
    time ovftool --name="t${teamnumber}-vm${i}" --datastore="ahd" \
	 --net:"VM Network"="t${teamnumber}-net5-pg" --net:"pg1"="t${teamnumber}-net4-pg" \
	 -dm=thin /root/ovftool/centos68-x86-autoconf16.ovf vi://root:Wakame4Axsh@192.168.1.219
done
