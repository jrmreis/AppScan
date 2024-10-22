#!/bin/bash
# Connect to ASOC (AppScan on Cloud) get scanIds in a period of time and delete all scans keeping all issues.
# Before use, set variables ASOCkeyId and ASOCkeySecret.
# How to use:
# ./deleteScans.sh <startDate> <endDate>
# Example:
# ./deleteScans.sh 2022-07-01 2022-07-31

############### Variable to be filled ###############
ASOCkeyId='xxxxxxxxxxxxxxxxxxxxxxxxxxx'
ASOCkeySecret='xxxxxxxxxxxxxxxxxxxxxxxxxxx'
################### End Variables ###################

startDate=$1
endDate=$2

ASOCtoken=$(curl -s -X POST --header 'Content-Type: application/json' --header 'Accept: application/json' -d '{"KeyId":"'"${ASOCkeyId}"'","KeySecret":"'"${ASOCkeySecret}"'"}' 'https://cloud.appscan.com/api/V2/Account/ApiKeyLogin' | jq -r .Token)

scanIdCount=$(curl --header 'Content-Type: application/json' --header 'Accept: application/json' --header "Authorization: Bearer $ASOCtoken"  'https://cloud.appscan.com/api/v2/Scans/GetAsPage?&$filter=((Technology%20eq%20%27StaticAnalyzer%27))and(LatestExecution/ExecutedAt%20gt%20datetime%27'"$startDate"'T03:00:00.000Z%27%20and%20LatestExecution/ExecutedAt%20lt%20datetime%27'"$endDate"'T02:59:59.000Z%27)&$inlinecount=allPages' | jq -r .Items[].Id | wc -l)

scanIdCountArray="$((scanIdCount-1))"

scanIds=($(curl --header 'Content-Type: application/json' --header 'Accept: application/json' --header "Authorization: Bearer $ASOCtoken" 'https://cloud.appscan.com/api/v2/Scans/GetAsPage?&$filter=((Technology%20eq%20%27StaticAnalyzer%27))and(LatestExecution/ExecutedAt%20gt%20datetime%27'"$startDate"'T03:00:00.000Z%27%20and%20LatestExecution/ExecutedAt%20lt%20datetime%27'"$endDate"'T02:59:59.000Z%27)&$inlinecount=allPages' | jq -r .Items[].Id))

for i in ${!scanIds[@]}
  do 
    echo "Element $i, scanid ${scanIds[$i]} deleted";  
    curl -X 'DELETE' --header 'Content-Type: application/json' --header 'Accept: application/json' --header "Authorization: Bearer $ASOCtoken"  "https://cloud.appscan.com/api/V2/Scans/${scanIds[$i]}?deleteIssues=false"
  done
