#!/bin/bash

failed()
{
    echo  "Failed...exiting: $@" 1>&2
    exit 255
}

[ -f ./vmwd.conf ] || failed "vmwd.conf must be in current directory"
[ -d ./www ] || failed "www directory must already exist"

source ./vmwd.conf

# make sure these are set
( : ${esxi_ip:?}
  : ${esxi_storage:?}
) || failed "The parameters should be set in vmwd.conf"

ssh root@$esxi_ip >www/rawmacs <<'EOF'
   grep 'generatedAddress =' $(find /vmfs/ -name '*.vmx') | grep -o '/[^/]*$'
EOF

rawmacs="$(cat www/rawmacs)"

# make sure no quotes slipped in that would mess up the code below
rawmacs="${rawmacs//\'/}"

cat >www/config-dispatch.sh <<EOF
#!/bin/bash

echo "Running config-dispatch.sh built at $(date)"

raw_mac_info='$rawmacs
'

EOF

cat www/static-part-of-config-dispatch.sh >>www/config-dispatch.sh
