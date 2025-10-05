#  Repo Rundown
This repo contains tools for triaging macOS in order to get details on TCC.
The structure is as follows:

  - compute_services.sh
  - get_data.sh
  - get_entitlements.sh
  - query_wrapper.sh
- **tools**
  - collect_vm_data.sh
  - extract_data.sh
  - vm_runner.sh 

**src** contains all the scripts that find information on TCC inside the system.
**tools** contains scripts for automating the process of gathering data from VMs, downloading and extracting that data onto the host machine.
*./script -h* to get the usage.

### compute_services.sh
Gets all(?) services (or TCC policies) gathered from plists and the tccd binary.
Used this as reference: https://www.rainforestqa.com/blog/macos-tcc-db-deep-dive

### get_data.sh
Runs all other scripts in the root directory of this repo.

### get_entitlements.sh
Searches for entitled binaries throughout the system, based on hardcoded paths and prints the binaries and their entitlements. Can be used to find TCC-entitled applications only.
Can also be used as a codesign wrapper for querying a simple application.

### query_wrapper.py
It's a wrapper over sqlite3 queries. Gets info such as all recorded clients in a user's TCC.db and the root TCC.db.
You can also query it to output services used by an app/process/client and vice versa (given a service, which clients use that service?).

# tools
### collect_vm_data.sh
Does an ssh onto the vm, jumps to the **already cloned** repo on that machine, cleans and pulls the latest changes. It runs *./get_data.sh* to create an archive and scp to download it on the host.

### extract_data.sh
Extracts the data from the archives created by *collect_vm_data.sh*

### vm_runner.sh
Uses UTM cli utility to open the VMs based on their name and does a *collect_vm_data.sh* on each of them.

# Setup
*query_wrapper.py* requires Terminal.app to have FDA (Full Disk Access).

### Automation
*collect_data.sh* requires:
 - ssh-copy-id to remove password requirement.
 - git clone \<repo> onto that VM

*vm_runner.sh* requires:
 - UTM (https://mac.getutm.app/) be installed
 - VMs are created and contain **mac** in their name
 - On the host machine, in the ssh config, the vms are named **vm\<number>**
