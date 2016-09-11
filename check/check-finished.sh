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
    echo -n "Team $tn     $vm: "
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

cat >~/.ssh/config <<'EOF2'
Host *
  KeepAlive yes
  ForwardAgent no
  ServerAliveInterval 60
  GSSAPIAuthentication no
EOF2
chmod 600 ~/.ssh/config

for i in 4.11 4.12 4.21 4.22 5.11 5.12 5.13; do
  vmssh="ssh -T centos@192.168.\$i"
  fcheckoutput "$teamnumber" "\$i" "\$(\$vmssh sudo ls /root/hide)"
  echo "    \$(\$vmssh hostname)"
done

EOF
    echo
}

for i in "$@"; do
    check-one-finished "$i"
done
