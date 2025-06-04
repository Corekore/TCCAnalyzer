#!/bin/bash

appPath="$1"

usage() {
  echo "Usage: ./get_entitlements.sh <path/to/Application.{app|appex|bundle}>"
  echo "Usage: ./get_entitlements.sh -t <path/to/Application.{app|appex|bundle}>"
}

getEntitlements() {
  echo "[*] Step 0"
  echo "[*] Getting entitlements for ${appPath}"
  codesign -d --ent - "${appPath}"

  echo "[*] Step 1"
  if [ -d "${appPath}Contents/Frameworks" ]; then
    while IFS= read -r -d '' dir; do
      echo "[*] Getting entitlements for ${dir}"
      codesign -d --ent - "${dir}"
    done < <(find "${appPath}Contents/Frameworks" -maxdepth 1 -iname "*.app" -print0)
  fi

  echo "[*] Step 2"
  if [ -d "${appPath}Contents/PlugIns" ]; then
    while IFS= read -r -d '' dir; do
      echo "[*] Getting entitlements for ${dir}"
      codesign -d --ent - "${dir}"
    done < <(find "${appPath}Contents/PlugIns" -maxdepth 1 -iname "*.app" -print0)
  fi

  echo "[*] Step 3"
  if [ -d "${appPath}Contents/Extensions" ]; then
    while IFS= read -r -d '' dir; do
      echo "[*] Getting entitlements for ${dir}"
      codesign -d --ent - "${dir}"
    done < <(find "${appPath}Contents/Extensions" -maxdepth 1 -iname "*.app" -print0)
  fi

  echo "[*] Step 4"
  if [ -d "${appPath}Contents/Library" ]; then
    echo "[?] Library dir spotted. Search for apps by hand." 
  fi
}

getCommon() {
  SCRIPT_PATH="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
  if [ ! -d "${SCRIPT_PATH}/ent_output" ]; then
    mkdir "${SCRIPT_PATH}/ent_output"
  fi

  # common paths to search for apps?
  declare -a commonPaths=("/Applications"
                          "/System/Applications"
                          "/System/Library/Frameworks"
                          "/System/Library/PrivateFrameworks"
                         )

  # check each relevant path in turn
  for path in "${commonPaths[@]}"; do
    while IFS= read -r -d '' file; do
      # change the path of the app bundle to be analyzed by getEntitlements
      appPath="${file}"
      getEntitlements >> "${SCRIPT_PATH}/ent_output/commonApplications"
    done < <(find "${path}" -maxdepth 1 -iname "*.app" -print0)
  done
}

while getopts 'thc' opt; do
  case "$opt" in
    t) echo "[*] Getting tcc-related entitlements"
       appPath="$2"
       getEntitlements | grep -e "Getting" -e "tcc" -e "kTCC"
       exit 0;;
    h) usage; exit 0;;
    c) getCommon; exit 0;;
    *) usage &>2; exit 1;; 
  esac
done
# shift $((OPTIND - 1))

# no arguments supplied
if [ $# -eq 0 ]; then
  usage
else
  getEntitlements
fi