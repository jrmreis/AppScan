# ImportAppIssues from ASOC to ASE
This script was created to get SAST issues from a specific Application in AppScan on Cloud and import in an Application in AppScan Enterprise (tested 10.0.5 and 10.0.6).

Requirements:
- Account in ASOC and ASE
- KeyPair in both solutions
	- ASOC Documentation: https://help.hcltechsw.com/appscan/ASoC/appseccloud_generate_api_key_cm.html	
	- ASE - Access ASE, click in "AppScan Enterprise REST APIs" on main menu, click in "Account", click in "POST /account/apikey" and click on button "Execute Request"
```bash 
#!/bin/bash
# Connect to ASOC (AppScan on Cloud) get SAST Report and import in ASE (AppScan Enterprise). This script is set to SAST Reports. It was tested with ASE 10.0.5 and 10.0.6.
# Before use, set variables ASOCkeyId, ASOCkeySecret, ASEhostname, ASEkeyId and ASEkeySecret.

# How to use:
# ./importIssuesfromASOCtoASE.sh <ASOC_Application_ID> <Report_Name>.xml <ASE_Application_ID>
# Example:
# ./importIssuesfromASOCtoASE.sh 5ebfa225-1234-4bb0-abcd-f3cef742be14 app_ecommerce_sast.xml 1015

############### Variable to be filled ###############
ASOCkeyId=xxxxxxxxxxxxxxxxxxxx
ASOCkeySecret=xxxxxxxxxxxxxxxxxxxx

ASEhostname=xxxxxxxxxxxxxxxxxxxx
ASEkeyId=xxxxxxxxxxxxxxxxxxxx
ASEkeySecret=xxxxxxxxxxxxxxxxxxxx
################### End Variables ###################

ASOCappId=$1
reportTitle=$2
ASEappId=$3

# Authenticate in ASOC and get ASOC Token. Input: ASOCkeyId, ASOCkeySecret ; Output: ASOCtoken
ASOCtoken=$(curl -s -X POST --header 'Content-Type: application/json' --header 'Accept: application/json' -d '{"KeyId":"'"${ASOCkeyId}"'","KeySecret":"'"${ASOCkeySecret}"'"}' 'https://cloud.appscan.com/api/V2/Account/ApiKeyLogin' | grep -oP '(?<="Token":")[^"]*')

# Generate issues security report to a specific application. Input: ASOCtoken, reportTitle, ASOCappId, Report Config; Output: reportId
reportId=$(curl -s -X POST --header 'Content-Type: application/json' --header 'Accept: application/json' --header "Authorization: Bearer $ASOCtoken" -d '{"Configuration":{"Summary":true,"Details":true,"Discussion":true,"Overview":true,"TableOfContent":true,"Articles":true,"Advisories":true,"FixRecommendation":true,"History":true,"Coverage": true,"MinimizeDetails":true,"ReportFileType":"XML","Title":"'"$reportTitle"'","Notes":"","Locale":"en"},"OdataFilter":"","ApplyPolicies":"None"}}' "https://cloud.appscan.com/api/v2/Reports/Security/Application/$ASOCappId" | grep -oP '(?<="Id":")[^"]*')

# Wait report ready and download it
for x in {1..30}
  do
    curl -s -X GET --header 'Accept: text/xml' --header "Authorization: Bearer $ASOCtoken" "https://cloud.appscan.com/api/v2/Reports/Download/$reportId" > $reportTitle
    if [[ -s $reportTitle ]] 
	then
      break
  fi
  sleep 1
done

# Change and add some contents in XML report file to be acceptable during ASE import. Input: Report XML file
sed -i 's/technology="Mixed"/technology="SAST" xmlExportVersion="2.4"/' $reportTitle
sed -i '3 i <fix-recommendation-group></fix-recommendation-group>' $reportTitle

# Authenticate in ASE with KeyPair and generate a sessionId to be used in next interations. Input: KeyId, KeySecret, ASEhostname; Output: sessionID
sessionId=$(curl -s -X POST --header 'Content-Type: application/json' --header 'Accept: application/json' -d '{"keyId":"'"$ASEkeyId"'","keySecret":"'"$ASEkeySecret"'"}' "https://$ASEhostname:9443/ase/api/keylogin/apikeylogin" --insecure | grep -oP '(?<="sessionId":")[^"]*')

# Generate a random name file to be used during import process. It will keep unique each import.
scanName=$(echo $RANDOM)_asoc_export

# Import ASoC XML file into ASE. Input: sessionId, scanName, reportTitle, ASEhostname, ASEappId; Output: Issues in specific app in ASE
curl -s --header 'X-Requested-With: XMLHttpRequest' --header "Cookie: asc_session_id=$sessionId;" --header "Asc_xsrf_token: $sessionId" -F "scanName=$scanName" -F "uploadedfile=@$reportTitle" "https://$ASEhostname:9443/ase/api/issueimport/$ASEappId/3/" --insecure | grep -oP inprogress

# Change XML filename to keep track. It can be deleted.
reportFileName=$scanName-$reportTitle
mv $reportTitle $reportFileName
```
