#!/bin/bash

failed()
{
    echo  "Failed...exiting: $@" 1>&2
    exit 255
}


fcheckoutput()
{
    tn="$1"
    vm="$2"
    results="$3"
    echo -n "Team $tn $vm: "
    if [[ "$results" == *poll-for-vm-auto-conf.sh* ]]; then
	echo OK
    else
	echo ---
    fi
}


check-one-finished()
{
    teamnumber="$1"

    gwssh="ssh -T centos@192.168.100.$(( teamnumber + 10 ))"
    fcheckoutput "$teamnumber" "gw" "$($gwssh sudo ls /root/hide)"
    
    $gwssh <<EOF
$(declare -f fcheckoutput)

for i in 11 12 21 22 31 32 33; do
  vmssh="ssh -T centos@192.168.100.\$i"
  fcheckoutput "$teamnumber" "\$i" "$($gwssh sudo ls /root/hide)"
done

EOF
    echo
}

for i in "$@"; do
    check-one-finished "$i"
done
