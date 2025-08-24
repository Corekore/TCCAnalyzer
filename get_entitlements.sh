#!/bin/bash

appPath="$1"
tUsed=false

usage() {
  echo "Usage: ./get_entitlements.sh -h"
  echo "       ./get_entitlements.sh <path/to/Application.{app|appex|bundle}>"
  echo "       ./get_entitlements.sh -t <path/to/Application.{app|appex|bundle}>"
  echo "       ./get_entitlements.sh -c"
  echo "       ./get_entitlements.sh -tc"
  echo "       ./get_entitlements.sh -a"
}

getEntitlements() {
  echo "[*] Step 0 - Getting entitlements for ${appPath}"
  codesign -d --ent - "${appPath}"

  #echo "[*] Step 1 - Check for Frameworks"
  if [ -d "${appPath}/Contents/Frameworks" ]; then
    echo "[!] Frameworks dir spotted"
    while IFS= read -r -d '' dir; do
      echo "[*] Getting entitlements for ${dir}"
      codesign -d --ent - "${dir}"
    done < <(find "${appPath}/Contents/Frameworks" -maxdepth 1 -iname "*.app" -print0)
  fi

  #echo "[*] Step 2 - Check for PlugIns"
  if [ -d "${appPath}/Contents/PlugIns" ]; then
    echo "[!] PlugIns dir spotted"
    while IFS= read -r -d '' dir; do
      echo "[*] Getting entitlements for ${dir}"
      codesign -d --ent - "${dir}"
    done < <(find "${appPath}/Contents/PlugIns" -maxdepth 1 -iname "*.appex" -print0)
  fi

  #echo "[*] Step 3 - Check for Extensions"
  if [ -d "${appPath}/Contents/Extensions" ]; then
    echo "[!] Extensions dir spotted"
    while IFS= read -r -d '' dir; do
      echo "[*] Getting entitlements for ${dir}"
      codesign -d --ent - "${dir}"
    done < <(find "${appPath}/Contents/Extensions" -maxdepth 1 -iname "*.appex" -print0)
  fi

  #echo "[*] Step 4 - Check for Library"
  if [ -d "${appPath}/Contents/Library" ]; then
    echo "[!] Library dir spotted. Search for apps by hand."
  fi
}

getTCCEntitlements()
{
  getEntitlements | grep -e "Getting" -e "tcc" -e "kTCC" -e "spotted" -e "Step"
}

getEntFromFrameworkBinaries()
{
  declare -a frameworkPaths=("/System/Library/Frameworks"
                             "/System/Library/PrivateFrameworks"
                            )
  for fwPath in "${frameworkPaths[@]}"; do
    echo "[*] Step - Check ${fwPath}"
    while IFS= read -r -d '' file; do
      echo "[*] Getting entitlements for" "${file}"/*
      codesign -d --ent - "${file}"/*
    done < <(find "${fwPath}" -name "MacOS" -print0)
  done
}

getTCCEntFromFrameworkBinaries()
{
  getEntFromFrameworkBinaries | grep -e "Getting" -e "tcc" -e "kTCC" -e "spotted" -e "Step"
}

getCommon() {
  # save dir where script is called from
  SCRIPT_PATH="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
  OUTDIR_PATH="${SCRIPT_PATH}/ent_output"

  if [ "$tUsed" = true ]; then
    echo "[*] Getting tcc-related entitlements"
    getEntRunner=getTCCEntitlements
    getFrameworkEntRunner=getTCCEntFromFrameworkBinaries
    OUTFILE_PATH="${OUTDIR_PATH}/commonApplicationsEntitlements_TCC"
  else
    echo "[*] Getting all entitlements"
    getEntRunner=getEntitlements
    getFrameworkEntRunner=getEntFromFrameworkBinaries
    OUTFILE_PATH="${OUTDIR_PATH}/commonApplicationsEntitlements"
  fi

  if [ ! -d "$OUTDIR_PATH" ]; then
    mkdir "$OUTDIR_PATH"
  fi

  if [ -f "$OUTFILE_PATH" ]; then
    echo "[*] Removing previous commonApplications"
    rm "$OUTFILE_PATH"
  fi

  # common paths to search for apps?
  declare -a commonPaths=("/Applications"
                          "/System/Applications"
                         )

  # check each relevant path in turn
  for path in "${commonPaths[@]}"; do
    while IFS= read -r -d '' file; do
      # change the path of the app bundle to be analyzed by getEntitlements
      appPath="${file}"
      "$getEntRunner" >> "$OUTFILE_PATH"
    done < <(find "${path}" -maxdepth 1 -iname "*.app" -print0)
  done

  # searches and gets entitlements from apps inside of .framework directories
  "$getFrameworkEntRunner" frameworkPaths >> "$OUTFILE_PATH"
}

while getopts 'thca' opt; do
  case "$opt" in
    t) appPath="$2"; tUsed=true;; # don't put -t into appPath
    h) usage; exit 0;;
    c) getCommon; exit 0;;
    a) getCommon; tUsed=true; getCommon; exit 0;; # get both entitlement output files
    *) usage >&2; exit 1;;
  esac
done
# shift $((OPTIND - 1))

# no arguments supplied
if [ $# -eq 0 ]; then
  usage
elif [ "$tUsed" = true ]; then
  getTCCEntitlements
else
  getEntitlements
fi
