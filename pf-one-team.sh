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

IP=192.168.100.$(( 10 + 10#$teamnumber ))  # make sure leading zero does not switch to bash octal mode

# 2ttvv  tt=team number   vv=vm number  (from 11 12 21 22)
# e.g.  20101 = team 1 vm 11

pfparams="$(

  # e.g.: 20422 goes to team4's wakame2 VM
  for i in 11 12 21 22; do
      aport="2${teamnumber}${i}"
      echo -n  " -L ${aport}:192.168.4.${i}:22"
  done

  # and one for Wakame WebUI
  aport="2${teamnumber}90"
  echo -n  " -L ${aport}:192.168.4.21:9000"  # connect to wakame2 VM
)"

ssh root@"$IP" $pfparams -g  sleep 999${teamnumber}
