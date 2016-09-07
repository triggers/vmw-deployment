
# to be pasted as the last part of the script


get_local_macs()
{
    ip link | grep link/ether | while read a b c ; do echo $b ; done
    # example output:
    #00:0c:29:89:0a:b6
    #00:0c:29:89:0a:c0
}

mac_to_vm_name()
{
    # the result of the grep should look like this, e.g:
    #/mastergw.vmx:ethernet0.generatedAddress = "00:0c:29:89:0a:b6"
    #/mastergw.vmx:ethernet1.generatedAddress = "00:0c:29:89:0a:c0"

    vmname="$(
      grep -F "$(get_local_macs)" "$raw_mac_info" | \
	while IFS='/:' read vm thereset ; do 
           echo "$vm"
        done | sort -u
    )"
    # vmname should be one line
    [ "$(wc -l <<<"$vmname")" = "1" ] || \
	echo "Warning, multiple results from mac_to_vm_name: $vmname" 1>&2

    echo "${vmname%%.vmx*}" # returns only the first VM name
}

vm_to_script_name()
{
    case "$1" in
	*) echo default.sh
	   ;;
    esac
}

vmn="$(mac_to_vm_name)"
sn="$(vm_to_script_name "$vmn")"

curl http://192.168.100.1/$sn >>$sn

checkpat='#end of script#'
[[ "$(cat $sn)" ==  *$checkpat* ]]   || {
    echo "Download of $sn script failed." 1>&2
    exit 255
}

# run the script!
"$sn" "$vmn"
rc="$?"

if [ "$rc" = "0" ] ; then
    rm keep-polling  # stop script from being called again until the next VM boot
fi

echo "Script $sc returned error $rc" 1>&2

exit "$rc"

#end-of-script#  # <<-minimal check to make sure whole script was downloaded
