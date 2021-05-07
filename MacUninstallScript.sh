#!/bin/bash

while getopts u:p: flag 
do
    case "${flag}" in
    u) user=${OPTARG};;
    p) pass=${OPTARG};;
  esac
done

#Variables to set
uninstallName="MacUninstallScript.sh"

#Authenticate to obtain access_token
aToken=$(curl -X POST "https://api.crowdstrike.com/oauth2/token" -H "accept: application/json" -H "Content-Type: application/x-www-form-urlencoded" -d "client_id=$user&client_secret=$pass" | grep -i access_token | awk {'print $2'} | sed 's/["{,]//g')

#Get ID of the host
hostID=$(/Library/CS/falconctl stats | grep agentID | awk {'print $2'} | sed 's/-//g')

#Get Uninstall Token
uToken=$(curl -X POST "https://api.crowdstrike.com/policy/combined/reveal-uninstall-token/v1" -H "accept:application/json" -H 'authorization: Bearer '${aToken}'' -H "Content-Type:application/json" -d "{\"audit_message\":\"Reveal\",\"device_id\":\"$hostID\"}" |grep -i token | sed 's/["{,]//g' | awk {'print $2'})

#Uninstall the sensor using the Uninstall Token
/usr/bin/expect <(cat <<EOF
spawn /Library/CS/falconctl uninstall --maintenance-token
expect "Falcon Maintenance Token:"
send "$uToken\r"
interact
EOF
)

#Remove script from host endpoint after uninstall
rm $uninstallName
