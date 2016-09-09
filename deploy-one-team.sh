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

eee() { $eee "$@" ; }

eee() { echo $eee "$@" ; }  # disable for now

for i in 1 2 3; do
    eee network vswitch standard add -v t${teamnumber}-net${i}
    eee network vswitch standard portgroup add -p t02-net1-pg -v t${teamnumber}-net${i}
done

time ovftool --name="gw${teamnumber}" --datastore="ahd" \
     --net:"VM Network"="class-net-pg" --net:"pg1"="t${teamnumber}-net1-pg" \
     -dm=thin /root/ovftool/centos68-x86-autoconf16.ovf vi://root:Wakame4Axsh@192.168.1.219

for i in 01 02; do
    time ovftool --name="t${teamnumber}-vm${i}" --datastore="ahd" \
	 --net:"VM Network"="t${teamnumber}-net2-pg" --net:"pg1"="t${teamnumber}-net1-pg" \
	 -dm=thin /root/ovftool/centos68-x86-autoconf16.ovf vi://root:Wakame4Axsh@192.168.1.219
done

for i in 03 04; do
    time ovftool --name="t${teamnumber}-vm${i}" --datastore="ahd" \
	 --net:"VM Network"="t${teamnumber}-net3-pg" --net:"pg1"="t${teamnumber}-net1-pg" \
	 -dm=thin /root/ovftool/centos68-x86-autoconf16.ovf vi://root:Wakame4Axsh@192.168.1.219
done
