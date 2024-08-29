#!/usr/bin/python3
import os
import sys

# global vars
rootDBFile = "/Library/Application\ Support/com.apple.TCC/TCC.db "
userDBFile = "~/Library/Application\ Support/com.apple.TCC/TCC.db "

def removeDuplicates():
  os.chdir("output/")
  for file in os.listdir(): 
    # print(f"Removing duplicates in {file}")
    newFilename = file.replace("_raw", "") 
    os.system(f"sort {file} | uniq > {newFilename}") 
    os.remove(file)

def fetchAllInfo():
  if not os.path.isdir("output"):
    os.mkdir("output")

  print("Getting all available services")
  command = "\"select service from access;\""
  os.system("sqlite3 " + rootDBFile + command + " | tee output/root_services_raw output/available_services_raw > /dev/null")
  os.system("sqlite3 " + userDBFile + command + " | tee output/user_services_raw >> output/available_services_raw")

  print("Getting all available clients")
  command = "\"select client from access;\""
  os.system("sqlite3 " + rootDBFile + command + " | tee output/root_clients_raw output/available_clients_raw > /dev/null")
  os.system("sqlite3 " + userDBFile + command + " | tee output/user_clients_raw >> output/available_clients_raw")

  # remove duplicates
  removeDuplicates()

def getClients(service):
  command = f"\"select client from access where service = '{service}';\""
  print("From root db:")
  os.system("sqlite3 " + rootDBFile + " " + command)
  print("From user db:")
  os.system("sqlite3 " + userDBFile + " " + command)

def getServices(client):
  command = f"\"select service from access where client = '{client}';\""
  print("From root db:")
  os.system("sqlite3 " + rootDBFile + " " + command)
  print("From user db:")
  os.system("sqlite3 " + userDBFile + " " + command)

def main():
  if len(sys.argv) == 1:
    print("Fetching information from both root TCC.db and user TCC.db")
    fetchAllInfo()
  elif sys.argv[1] == "-h":
    print("Usage: ./query_wrapper.py (-h help) (-s <service_name>) (-c <client_name>)"
          "Example: ./query_wrapper.py -s kTCCServiceSystemPolicyAllFiles"
          "         ./query_wrapper.py -c com.apple.Terminal")
  elif sys.argv[1] == "-c":
    print("Getting all services used by client: " + sys.argv[2])
    getServices(sys.argv[2])
  elif sys.argv[1] == "-s":
    print("Getting all clients that use service: " + sys.argv[2])
    getClients(sys.argv[2])

if __name__ == "__main__":
  main()
