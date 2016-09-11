#!/bin/bash

failed()
{
    echo  "Failed...exiting: $@" 1>&2
    exit 255
}


ssh-check-one()
{
    teamnumber="$1"

    gwssh="ssh -T centos@192.168.100.$(( teamnumber + 10 ))"

    $gwssh <<EOF
cat >~/.ssh/config <<'EOF2'
Host *
  KeepAlive yes
  ForwardAgent no
  ServerAliveInterval 60
  GSSAPIAuthentication no
  StrictHostKeyChecking no
  UserKnownHostsFile /dev/null
EOF2
chmod 600 ~/.ssh/config

for i in 4.11 4.12 4.21 4.22 5.11 5.12 5.13; do
  vmssh="ssh -T centos@192.168.\$i"
  echo
  echo "==================== $teamnumber  \$i  ::"
  \$vmssh $thecmd
done

EOF
}

thecmd="$1"
shift

for i in "$@"; do
    ssh-check-one "$i"
done
