# Integration AppScan Enterprise (DAST) and Gitlab
<br>
Gitlab YAML file to integrate AppScan Enterprise (DAST feature) and Gitlab Pipeline enabling send DAST scans requests to AppScan Enterprise and keep result reports in Gitlab.
Gitlab will start scan, generate report, publish results in AppScan Enterprise and check for Security Gate.<br>
<br>
Requirements:<br>
1 - AppScan Enterprise and AppScan Dynamic Analysis tool.<br>
2 - Gitlab Runner for Linux, because this YAML will run in Linux Environment.<br>
3 - Optional: You can use a Login Recorded file. Generate the file and copy in repository root folder.<br>
4 - Fill variables.<br>
4.1 - About Security Gate, the sevSecGw options are criticalIssues, highIssues, mediumIssues and lowIssues.The maxIssuesAllowed is the amount of issues in selected sevSecGw. Example: If you set sevSecGw as criticalIssues, maxIssuesAllowed as 10 and the scan result found 11 criticalIssues, the build will fail.<br>

```yaml
variables:
  urlTarget: http://www.abcd.com/
  fileDastConfig: login.dast.config
  aseHostname: appscanenterprise.com:9443
  aseApiKeyId: XXXXXXXXXXXXX
  aseApiKeySecret: XXXXXXXXXXXXX
  aseAppName: App1
  sevSecGw: highIssues
  maxIssuesAllowed: 10

stages:
- scan

scan-job:
  stage: scan
  script:
  - > 
    sessionId=$(curl -s -X POST --header 'Content-Type: application/json' --header 'Accept: application/json' -d '{"keyId":"'"$aseApiKeyId"'","keySecret":"'"$aseApiKeySecret"'"}' "https://$aseHostname/ase/api/keylogin/apikeylogin" --insecure | grep -oP '(?<="sessionId":")[^"]*')
  - echo "Session ID is $sessionId. The Session ID will be used in all subsequent ASE API calls."
  - > 
    applicationId=$(curl -s -X GET --header 'Accept: application/json' --header 'Range: items=0-1000' --header "Asc_xsrf_token: $sessionId" --header "Cookie: asc_session_id=$sessionId;" "https://$aseHostname/ase/api/applications" --insecure | jq | jq '.[] | select(.name == "'"$aseAppName"'")' | grep -oP '(?<="id": ")[^"]*')
  - echo "Application name is $aseAppName and application ID is $applicationId. The issues found will be published into this Application"
  - scanName=$(echo $RANDOM)_scan
  - echo "Scan name will be $scanName. You can filter all issues found through Scan Name:$scanName ($jobId)"
  - >
    jobId=$(curl -s --header 'Content-Type: application/json' --header 'Accept: application/json' --header "Cookie: asc_session_id=$sessionId;" --header "Asc_xsrf_token: $sessionId" -d '{"testPolicyId":"3","folderId":"1","applicationId":"'$applicationId'","name":"'$scanName'","description":"","contact":""}'  "https://$aseHostname/ase/api/jobs/17/dastconfig/createjob" --insecure | grep -oP '(?<="id":)[^,]*')
  - echo "The JobId was created, its name is $jobId and its located in ASE folder"
  - >
    curl -s --header 'Content-Type: application/json' --header 'Accept: application/json' --header "Cookie: asc_session_id=$sessionId;" --header "Asc_xsrf_token: $sessionId" -d '{"scantNodeXpath":"StartingUrl","scantNodeNewValue":"'"$urlTarget"'"}' "https://$aseHostname/ase/api/jobs/$jobId/dastconfig/updatescant" --insecure
  - echo "The URL Target was updated in Job Id. It was updated to $urlTarget"
  - > 
    if [ -f "$fileDastConfig" ]; then
      echo "$fileDastConfig exists. So it will be uploaded to the Job and will be used to Authenticate in the URL Target during tests."
      curl -s --header 'X-Requested-With: XMLHttpRequest' --header "Cookie: asc_session_id=$sessionId;" --header "Asc_xsrf_token: $sessionId" -F "uploadedfile=@$fileDastConfig" "https://$aseHostname/ase/api/jobs/$jobId/dastconfig/updatetraffic/login" --insecure
    fi
  - >
    Etag=$(curl -s -I --header 'Content-Type: application/json' --header 'Accept: application/json' --header "Cookie: asc_session_id=$sessionId;" --header "Asc_xsrf_token: $sessionId" "https://$aseHostname/ase/api/jobs/$jobId" --insecure | grep -oP '(?<=ETag: ")[^"]*')
  - echo "The Etag is $Etag. It is used to verify that is jobs state has not been changed or updated before making the changes to the job."
  - >
    curl -s --header 'Content-Type: application/json' --header 'Accept: application/json' --header "Cookie: asc_session_id=$sessionId;" --header "Asc_xsrf_token: $sessionId" --header "If-Match: \"$Etag\"" -d '{"type":"run"}' "https://$aseHostname/ase/api/jobs/$jobId/actions?isIncremental=false&isRetest=false&basejobId=-1" --insecure
  - echo "Scan started."
  - sleep 60
  - >  
    for x in $(seq 1 1000)
      do
        scanStatus=$(curl -s --header 'Content-Type: application/json' --header 'Accept: application/json' --header "Cookie: asc_session_id=$sessionId;" --header "Asc_xsrf_token: $sessionId" "https://$aseHostname/ase/api/folderitems/$jobId/statistics" --insecure | grep -oP '(?<="status":")[^"]*')
        echo $scanStatus 
        if [ "$scanStatus" == "Ready" ]
          then break
        fi
        sleep 60
      done
  - echo "Scan finished. Requesting report generation."
  - >
    reportId=$(curl -s -X POST --header 'Content-type: application/json' --header "Asc_xsrf_token: $sessionId" --header "Cookie: asc_session_id=$sessionId;" --header 'Accept: application/json' -d '{"config":{"executiveSummaryIncluded":true,"advisoriesIncluded":true,"pdfPageBreakOnIssue":false,"sortByURL":false,"applicationAttributeConfig":{"showEmptyValues":false,"attributeLookups":[""]},"issueConfig":{"includeAdditionalInfo":false,"variantConfig":{"variantLimit":0,"requestResponseIncluded":false,"trafficCharactersCount":0,"differencesIncluded":false},"issueAttributeConfig":{"showEmptyValues":false,"attributeLookups":[""]}}},"layout":{"reportOptionLayoutCoverPage":{"companyLogo":"","additionalLogo":"","includeDate":false,"includeReportType":false,"reportTitle":"","description":""},"reportOptionLayoutBody":{"header":"","footer":""},"includeTableOfContents":true},"reportFileType":"PDF","issueIdsAndQueries":["scanname='$scanName' ('$jobId')"]}' "https://$aseHostname/ase/api/issues/reports/securitydetails?appId=$applicationId" --insecure | grep -oP '(?<="Report id: )[^"]*')
  - echo "The report Id is $reportId"
  - sleep 60
  - echo "Waiting Report."
  - >
    for x in {1..100};
    do 
      statusReport=$(curl -I -X GET --header 'Accept: application/json' --header "Asc_xsrf_token: $sessionId" --header "Cookie: asc_session_id=$sessionId;" "https://$aseHostname/ase/api/issues/reports/$reportId/status" --insecure | grep -oP "200|201|404")
      echo "The report status is $statusReport. When 201, the report generation is finished."
      if [ "$statusReport" == "201" ] 
        then
          echo "Report ready."
          break
      elif [ "$statusReport" == "404" ] 
        then
          echo "Report generation failed."
          exit 1 
      fi
      sleep 60
    done
  - echo "Downloading Report Id $reportId"
  - >
    curl -s -X GET --header "Asc_xsrf_token: $sessionId" --header "Cookie: asc_session_id=$sessionId;" --header 'Accept: application/octet-stream' "https://$aseHostname/ase/api/issues/reports/$reportId" --insecure --output $aseAppName-$reportId.zip
  - echo "Checking Security Gate."
  - > 
    criticalIssues=$(curl -s --header 'Content-Type: application/json' --header 'Accept: application/json' --header "Cookie: asc_session_id=$sessionId;" --header "Asc_xsrf_token: $sessionId" https://$aseHostname/ase/api/summaries/issues/count_v2?query=Application%20Name%3D$aseAppName%2CScan%20Name%3D$scanName%20%28$jobId%29%2CSeverity%3DCritical --insecure | tr -d '"')
  - >
    highIssues=$(curl -s --header 'Content-Type: application/json' --header 'Accept: application/json' --header "Cookie: asc_session_id=$sessionId;" --header "Asc_xsrf_token: $sessionId" https://$aseHostname/ase/api/summaries/issues/count_v2?query=Application%20Name%3D$aseAppName%2CScan%20Name%3D$scanName%20%28$jobId%29%2CSeverity%3DHigh --insecure | tr -d '"')
  - >
    mediumIssues=$(curl -s --header 'Content-Type: application/json' --header 'Accept: application/json' --header "Cookie: asc_session_id=$sessionId;" --header "Asc_xsrf_token: $sessionId" https://$aseHostname/ase/api/summaries/issues/count_v2?query=Application%20Name%3D$aseAppName%2CScan%20Name%3D$scanName%20%28$jobId%29%2CSeverity%3DMedium --insecure | tr -d '"')
  - >
    lowIssues=$(curl -s --header 'Content-Type: application/json' --header 'Accept: application/json' --header "Cookie: asc_session_id=$sessionId;" --header "Asc_xsrf_token: $sessionId" https://$aseHostname/ase/api/summaries/issues/count_v2?query=Application%20Name%3D$aseAppName%2CScan%20Name%3D$scanName%20%28$jobId%29%2CSeverity%3DLow --insecure | tr -d '"')

  - echo "There is $criticalIssues critical issues, $highIssues high issues, $mediumIssues medium issues and $lowIssues low issues."

  - >
    if [ "$criticalIssues" -gt "$maxIssuesAllowed" ] && [ "$sevSecGw" == "criticalIssues" ]
      then
        echo "The company policy permit less than $maxIssuesAllowed $sevSecGw severity"
        echo "Security Gate build failed"
        exit 1
    elif [ "$highIssues" -gt "$maxIssuesAllowed" ] && [ "$sevSecGw" == "highIssues" ]
      then
        echo "The company policy permit less than $maxIssuesAllowed $sevSecGw severity"
        echo "Security Gate build failed"
        exit 1
    elif [ "$mediumIssues" -gt "$maxIssuesAllowed" ] && [ "$sevSecGw" == "mediumIssues" ]
      then
        echo "The company policy permit less than $maxIssuesAllowed $sevSecGw severity"
        echo "Security Gate build failed"
        exit 1
    elif [ "$lowIssues" -gt "$maxIssuesAllowed" ] && [ "$sevSecGw" == "lowIssues" ]
      then
        echo "The company policy permit less than $maxIssuesAllowed $sevSecGw severity"
        echo "Security Gate build failed"
        exit 1
    fi
  - echo "Security Gate passed"  

  artifacts:
    when: always
    paths:
      - "*.zip"
```
