#!/bin/bash

output_path=$1

usage()
{
  echo "Usage: ./extract_data.sh <path/to/collected/vm/data>"
}

extract()
{
  for file in ${output_path}/*.tar; do
    extract_dir=${file//".tar"/}
    echo $file
    mkdir $extract_dir
    tar -xvf $file --directory $extract_dir
  done
}

if [ $# -eq 0 ]; then
  usage
else
  extract
fi
