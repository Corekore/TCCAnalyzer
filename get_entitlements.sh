#!/bin/bash

appPath="$1"

usage() {
  echo "Usage: ./get_entitlements.sh <path/to/Application.app>"
  echo "Usage: ./get_entitlements.sh -t <path/to/Application.app>"
}

getEntitlements() {
  echo "[*] Step 0"
  echo "[*] Getting entitlements for ${appPath}"
  codesign -d --ent - ${appPath}

  echo "[*] Step 1"
  if [ -d "${appPath}Contents/Frameworks" ]; then
    frameworksPath="${appPath}Contents/Frameworks"
    for dir in $(ls ${frameworksPath} | grep -e ".app"); do
      echo "[*] Getting entitlements for ${frameworksPath}/${dir}"
      codesign -d --ent - "${frameworksPath}/${dir}"
    done
  fi

  echo "[*] Step 2"
  if [ -d "${appPath}Contents/PlugIns" ]; then
    pluginPath="${appPath}Contents/PlugIns"
    for dir in $(ls ${pluginPath} | grep -e ".app"); do
      echo "[*] Getting entitlements for ${pluginPath}/${dir}"
      codesign -d --ent - "${pluginPath}/${dir}"
    done
  fi

  echo "[*] Step 3"
  if [ -d "${appPath}Contents/Extensions" ]; then
    extensionsPath="${appPath}Contents/Extensions"
    for dir in $(ls ${extensionsPath} | grep -e ".app"); do
      echo "[*] Getting entitlements for ${extensionsPath}/${dir}"
      codesign -d --ent - "${extensionsPath}/${dir}"
    done
  fi

  echo "[*] Step 4"
  if [ -d "${appPath}Contents/Library" ]; then
    echo "[?] Library dir spotted. Search for apps by hand." 
  fi
}

while getopts 'th' opt; do
  case "$opt" in
    t) echo "[*] Getting tcc-related entitlements"
       appPath="$2"
       getEntitlements | grep -e "Getting" -e "tcc" -e "kTCC"
       exit 0;;
    h) usage; exit 0;;
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