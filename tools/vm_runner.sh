#!/bin/bash

host=$HOST
vm_dirpath=$VM_DIRPATH

usage()
{
  echo "Usage: ./vm_runner.sh"
}

vm_runner()
{
  # get a list of vm's that contain "mac" in their name
  vms=($(utmctl list | awk '{print $3}' | tail -n +2 | grep "mac"))
  for ((i = 0; i < ${#vms[@]}; i++)); do
    printf "[*] Starting %s...\n" "${vms[i]}"
    utmctl start ${vms[i]}
    sleep 10
    printf "[*] Collecting data...\n"
    # using the name from the .ssh config file
    ./collect_vm_data.sh "vm$((i+1))" "$host" "$vm_dirpath"
    utmctl stop ${vms[i]}
    printf "[*] Stopping %s...\n" "${vms[i]}"
    sleep 10
  done
}

if [ $# -eq 0 ]; then
  vm_runner
else
  usage
fi