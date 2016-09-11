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

deploy_manual_for_one_team()
{
    teamnumber="$1"
    [[ "$teamnumber" == [0-9] ]] && teamnumber=0$teamnumber   # make the UI a little nicer
    [[ "$teamnumber" == [0-9][0-9] ]] || failed "Parameter must be two digit team number"
    
    for i in 01 02; do
	time ovftool --name="t${teamnumber}-vm${i}" --datastore="${esxi_storage}" \
	     --net:"VM Network"="t${teamnumber}-net2-pg" --net:"pg1"="t${teamnumber}-net1-pg" \
	     -dm=thin /root/ovftool/centos68-x86-autoconf16.ovf vi://root:${esxi_pw}@${esxi_ip}
    done
}

for t in "$@"; do
    deploy_manual_for_one_team "$t"
done
