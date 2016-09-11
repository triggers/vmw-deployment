#!/bin/bash

failed()
{
    echo  "Failed...exiting: $@" 1>&2
    exit 255
}

[ -f ./vmwd.conf ] || failed "vmwd.conf must be in current directory"

source ./vmwd.conf

# make sure these are set
( : ${esxi_ip:?}
  : ${esxi_pw:?}
  : ${esxi_storage:?}
) || failed "The parameters should be set in vmwd.conf"

deploy_gateway_for_one_team()
{
    teamnumber="$1"
    [[ "$teamnumber" == [0-9] ]] && teamnumber=0$teamnumber   # make the UI a little nicer
    [[ "$teamnumber" == [0-9][0-9] ]] || failed "Parameter must be two digit team number"
    
    time ovftool --name="gw${teamnumber}" --datastore="${esxi_storage}" \
	 --net:"class-net-pg"="class-net-pg" \
	 --net:"t02-net1-pg"="t${teamnumber}-net1-pg" \
	 --net:"t02-net4-pg"="t${teamnumber}-net4-pg" \
	 -dm=thin /root/ovftool/centos68-x86-autoconf16-3nic.ovf vi://root:${esxi_pw}@${esxi_ip}
}

for t in "$@"; do
    deploy_gateway_for_one_team "$t"
done
