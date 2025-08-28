#!/bin/bash

vm=$1
host=$2
vm_dirpath=$3

usage() {
  echo "Usage: ./collect_vm_data.sh vm@ip host@ip path/to/repo"
}

if [ $# -eq 0 ]; then
  usage
else
  ssh $vm <<ENDSSH
    cd "$vm_dirpath"
    rm -r ent_output/ output/ services/
    git pull
    ./get_data.sh
    version_string=\$(sw_vers | awk 'FNR==2 {print \$2}')
    tar -cvf macos_\${version_string}_output.tar ent_output/ output/ services/
    scp macos_\${version_string}_output.tar ${host}:~/Desktop
ENDSSH
fi
