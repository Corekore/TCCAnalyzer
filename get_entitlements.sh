#!/bin/bash
set -x

# declarations
appPath="$1"
tUsed=false
sUsed=false
declare -a filePaths  # save dir where script is called from
SCRIPT_PATH="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
OUTDIR_PATH="${SCRIPT_PATH}/ent_output"
SYSTEM_OUTFILE_PATH=""
USER_OUTFILE_PATH=""

usage() {
  echo "Usage: ./get_entitlements.sh -h"
  echo "       ./get_entitlements.sh <path/to/Application.{app|appex|bundle}>"
  echo "       ./get_entitlements.sh -t <path/to/Application.{app|appex|bundle}>"
  echo "       ./get_entitlements.sh -c"
  echo "Options: -t <path> prints tcc entitlements of that bundle"
  echo "         -c prints entitlements of user and system applications in separate files"
  echo "         -tc prints tcc entitlements of user and system applications in separate files"
  echo "         -a (all): runs -c and -tc"
  echo "         -s (sanitized): removes binaries that have no entitlements"
}

getEntitlements() {
  echo "[*] Step 0 - Getting entitlements for ${appPath}"
  codesign -d --ent - "${appPath}"

  # echo "[*] Step 1 - Check for Frameworks"
  if [ -d "${appPath}/Contents/Frameworks" ]; then
    # echo "[!] Frameworks dir spotted"
    while IFS= read -r -d '' dir; do
      echo "[*] Getting entitlements for ${dir}"
      codesign -d --ent - "${dir}"
    done < <(find "${appPath}/Contents/Frameworks" -maxdepth 1 -iname "*.app" -print0)
  fi

  #echo "[*] Step 2 - Check for PlugIns"
  if [ -d "${appPath}/Contents/PlugIns" ]; then
    # echo "[!] PlugIns dir spotted"
    while IFS= read -r -d '' dir; do
      echo "[*] Getting entitlements for ${dir}"
      codesign -d --ent - "${dir}"
    done < <(find "${appPath}/Contents/PlugIns" -maxdepth 1 -iname "*.appex" -print0)
  fi

  #echo "[*] Step 3 - Check for Extensions"
  if [ -d "${appPath}/Contents/Extensions" ]; then
    # echo "[!] Extensions dir spotted"
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

# from private frameworks basically
getEntFromFrameworkBinaries()
{
  declare -a frameworkPaths=(
                             "/System/Library/Frameworks"
                             "/System/Library/PrivateFrameworks"
                             "/Library/Apple/System/Library"
                             "/Library/Image Capture"
                             "/Library/Application Support"
                            #  "/Library/Developer"
                             "/Library/Spotlight"
                             "/Library/Extensions"
                             "/Library/Audio"
                             "/Library/Frameworks"
                            )

  for fwPath in "${frameworkPaths[@]}"; do
    echo "[*] Step - Check ${fwPath}"
    
    filePaths=($(find "${fwPath}" -type f -exec sh -c '
      for f; do
        if file "$f" | grep -q "Mach-O .* executable"; then
          printf "%s\n" "$f"
        fi
      done
    ' _ {} +))

    for file in "${filePaths[@]}"; do
      echo "[*] Getting entitlements for" "${file}"
      codesign -d --ent - "${file}"
    done
  done

  # lots of junk, we search binaries by MacOS directory
  echo "[*] Step - Check /Library/Developer"
  while IFS= read -r -d '' pathToMacOS; do
    # handle cases where there are multiple binaries in the same MacOS dir
    for file in "${pathToMacOS}"/*; do
      echo "[*] Getting entitlements for" "${file}"
      codesign -d --ent - "${file}"
    done
  done < <(find "/Library/Developer" -name "MacOS" -print0)
}

getEntFromSystemBinaries()
{
  declare -a systemPaths=(
                          "/usr/libexec"
                          "/usr/bin"
                          "/usr/sbin"
                         )
  for sysPath in "${systemPaths[@]}"; do
    echo "[*] Step - Check ${sysPath}"
    for file in "${sysPath}"/*; do
      echo "[*] Getting entitlements for" "${file}"
      codesign -d --ent - "${file}"
    done
  done
}

getTCCEntFromSystemBinaries() {
  getEntFromSystemBinaries | grep -e "Getting" -e "tcc" -e "kTCC" -e "spotted" -e "Step"
}

getTCCEntFromFrameworkBinaries()
{
  getEntFromFrameworkBinaries | grep -e "Getting" -e "tcc" -e "kTCC" -e "spotted" -e "Step"
}

getCommon() {


  if [ "$tUsed" = true ]; then
    echo "[*] Gathering tcc-related entitlements"
    getEntRunner=getTCCEntitlements
    getFrameworkEntRunner=getTCCEntFromFrameworkBinaries
    getEntFromSysBinRunner=getTCCEntFromSystemBinaries
    SYSTEM_OUTFILE_PATH="${OUTDIR_PATH}/systemApplicationsEntitlements_TCC"
    USER_OUTFILE_PATH="${OUTDIR_PATH}/userApplicationsEntitlements_TCC"
  else
    echo "[*] Gathering all entitlements"
    getEntRunner=getEntitlements
    getFrameworkEntRunner=getEntFromFrameworkBinaries
    getEntFromSysBinRunner=getEntFromSystemBinaries
    SYSTEM_OUTFILE_PATH="${OUTDIR_PATH}/systemApplicationsEntitlements"
    USER_OUTFILE_PATH="${OUTDIR_PATH}/userApplicationsEntitlements"
  fi

  if [ ! -d "$OUTDIR_PATH" ]; then
    mkdir "$OUTDIR_PATH"
  fi

  if [ -f "$SYSTEM_OUTFILE_PATH" ]; then
    echo "[*] Removing previous $SYSTEM_OUTFILE_PATH"
    rm "$SYSTEM_OUTFILE_PATH"
  fi

  if [ -f "$USER_OUTFILE_PATH" ]; then
    echo "[*] Removing previous $USER_OUTFILE_PATH"
    rm "$USER_OUTFILE_PATH"
  fi

  # common paths to search for apps?
  declare -a commonPaths=(
                          "/Applications"
                          "/System/Applications"
                         )

  # check each relevant path in turn
  for path in "${commonPaths[@]}"; do
    while IFS= read -r -d '' file; do
      # change the path of the app bundle to be analyzed by getEntitlements
      appPath="${file}"
      "$getEntRunner" >> "$USER_OUTFILE_PATH"
    done < <(find "${path}" -maxdepth 1 -iname "*.app" -print0)
  done

  # searches and gets entitlements from apps inside of .framework directories... and others!
  "$getFrameworkEntRunner" >> "$SYSTEM_OUTFILE_PATH"
  "$getEntFromSysBinRunner" >> "$SYSTEM_OUTFILE_PATH"

  if [ "$sUsed" = "true" ]; then
    echo "[*] Sanitizing..."
    sanitize
  fi
}

sanitize() {
  TMP_PATH="${OUTDIR_PATH}/tmp"
  FILE_LIST=("$USER_OUTFILE_PATH" "$SYSTEM_OUTFILE_PATH")
  for file in "${FILE_LIST[@]}"; do
    echo "[*] Sanitizing $file"
    echo "" > "$TMP_PATH"
    echo "" > "${TMP_PATH}2"
    # reverse the file, then keep the first occurence of "[*] Getting" in adjacent lines containing the string
    tail -r "$file" | perl -ne 'print unless $t and /^\[\*\] Getting/; $t = /^\[\*\] Getting/' >> "$TMP_PATH"
    tail -r "$TMP_PATH" >> "${TMP_PATH}2"
    cp "${TMP_PATH}2" "${file}_sanitized"
  done
  rm "$TMP_PATH" "${TMP_PATH}2"
}

while getopts 'hstca' opt; do
  case "$opt" in
    h) usage; exit 0;;
    s) sUsed=true;; # -sa creates sanitized output
    t) appPath="$2"; tUsed=true;; # don't put -t into appPath
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
