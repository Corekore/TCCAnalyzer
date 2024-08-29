#/bin/bash

# inspired by:
# https://www.rainforestqa.com/blog/macos-tcc-db-deep-dive
# the path mentioned in the article for the plist does not exist on my machine
# (macos 14.4), but Localizable.loctable seems to do the trick

path="/System/Library/PrivateFrameworks/TCC.framework/"
resources="${path}Resources/Localizable.loctable"
tccd="${path}Support/tccd"

# get raw outputs, sort and remove duplicates
plutil -p "${resources}" | grep -o 'kTCC[^_"]*' > ResourcesOutput 
sort ResourcesOutput | uniq > all_resources_services
rm ResourcesOutput

# some of these may be false positives; some may be used on other platforms (iOS, watchOS)
strings "${tccd}" | grep -o "kTCCService[^_'\"]*" | cut -d " " -f 1 > StringsOutput

# tail to delete kTCCService - unlikely this is a real policy
sort StringsOutput | uniq | tail -n +2 > all_strings_services
rm StringsOutput

# one final output file
# it's probably best to use a diffing utility to view which services each
# source brings such as diff (-y), meld
cat all_resources_services > all_services_raw
cat all_strings_services >> all_services_raw
sort all_services_raw | uniq > all_services
rm all_services_raw

if [ ! -d "services" ]; then
  mkdir services
fi
mv all_* services/
