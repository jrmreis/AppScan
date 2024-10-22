# getReportfromASE

````bash
#!/bin/bash

# Before first execution generate keyId and keySecret (https://asehostname:9443/ase/api/account/apikey)
# How to use:
# ./aseReportApplication.sh <applicationName>

############### Variable to be filled ###############
ASEhostname=xxxxxxxxxxxxxxxxxxx
ASEkeyId=xxxxxxxxxxxxxxxxxxx
ASEkeySecret=xxxxxxxxxxxxxxxxxxx
################### End Variables ###################

applicationName=$1

#Authenticate with KeyPair adn generate a sessionId to be used in next interations. This sessionId expire in a couple hours; Input: KeyId and KeySecret; Output: sessionID
sessionId=$(curl -s -X POST --header 'Content-Type: application/json' --header 'Accept: application/json' -d '{"keyId":"'"$ASEkeyId"'","keySecret":"'"$ASEkeySecret"'"}' "https://$ASEhostname:9443/ase/api/keylogin/apikeylogin" --insecure | grep -oP '(?<="sessionId":")[^"]*')

#Get applicationId based on command line argument. Input: sessionId, applicationName; Output: applicationId
applicationId=$(curl -s -X GET --header 'Accept: application/json' --header 'Range: items=0-1000' --header "Asc_xsrf_token: $sessionId" --header "Cookie: asc_session_id=$sessionId;" "https://$ASEhostname:9443/ase/api/applications" --insecure | jq | jq '.[] | select(.name == "'"$applicationName"'")' | grep -oP '(?<="id": ")[^"]*')

#Request report generation. Input: sessionId, report config (can be changed), applicationId. Output: reportId
reportId=$(curl -s -X POST --header 'Content-type: application/json' --header "Asc_xsrf_token: $sessionId" --header "Cookie: asc_session_id=$sessionId;" --header 'Accept: application/json' -d '{"config":{"executiveSummaryIncluded":false,"advisoriesIncluded":false,"pdfPageBreakOnIssue":false,"sortByURL":false,"applicationAttributeConfig":{"showEmptyValues":false,"attributeLookups":[""]},"issueConfig":{"includeAdditionalInfo":false,"variantConfig":{"variantLimit":0,"requestResponseIncluded":false,"trafficCharactersCount":0,"differencesIncluded":false},"issueAttributeConfig":{"showEmptyValues":false,"attributeLookups":[""]}}},"layout":{"reportOptionLayoutCoverPage":{"companyLogo":"","additionalLogo":"","includeDate":false,"includeReportType":false,"reportTitle":"","description":""},"reportOptionLayoutBody":{"header":"","footer":""},"includeTableOfContents":false},"reportFileType":"PDF","issueIdsAndQueries":[""]}' "https://$ASEhostname:9443/ase/api/issues/reports/securitydetails?appId=$applicationId" --insecure | grep -oP '(?<="Report id: )[^"]*') 

for x in {1..100}
  do statusReport=$(curl -s -X GET --header 'Accept: application/json' --header "Asc_xsrf_token: $sessionId" --header "Cookie: asc_session_id=$sessionId;" "https://$ASEhostname:9443/ase/api/issues/reports/$reportId/status" --insecure | grep -oP IN_PROGRESS)
    if [[ "$statusReport" != "IN_PROGRESS" ]]
	then
      break
  	fi
  sleep 1
done

#Report download. Input: session id, reportId, Report file name. Output: zipped report file
curl -s -X GET --header "Asc_xsrf_token: $sessionId" --header "Cookie: asc_session_id=$sessionId;" --header 'Accept: application/octet-stream' "https://$ASEhostname:9443/ase/api/issues/reports/$reportId" --insecure > $reportId.zip

# Change report filename
reportFileName=$applicationName-$reportId
mv $reportId.zip $reportFileName.zip
````
