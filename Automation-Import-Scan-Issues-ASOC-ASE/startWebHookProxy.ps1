###################################################################
# Update the variables on this block
$asocApiKeyId='aaaaaaaaaaaaaaaaaaaaaaaaa'
$asocApiKeySecret='aaaaaaaaaaaaaaaaaaaaaaaaa'
$presenceId='aaaaaaaaaaaaaaaaaaaaaaaaa'
$aseHostname='aaaaaaaaaaaaaaaaaaaaaaaaa'
$aseApiKeyId='aaaaaaaaaaaaaaaaaaaaaaaaa'
$aseApiKeySecret='aaaaaaaaaaaaaaaaaaaaaaaaa'
###################################################################

# Updating importScanResults.ps1 file
$importScriptContent=Get-Content .\importScanResults.ps1
$importScriptContent -replace "aseHostname='(.*)'" , "aseHostname='$aseHostname'" -replace "aseApiKeyId='(.*)'" , "aseApiKeyId='$aseApiKeyId'" -replace "aseApiKeySecret='(.*)'" , "aseApiKeySecret='$aseApiKeySecret'" | Out-File .\importScanResults.ps1

# Updating config.json file
$jsonConfig = Get-Content .\config.json | ConvertFrom-Json 
$jsonConfig.asoc_api_key.KeyId = $asocApiKeyId
$jsonConfig.asoc_api_key.KeySecret = $asocApiKeySecret
$jsonConfig.webhooks.asoc[0].PresenceId = $presenceId
$jsonConfig | ConvertTo-Json -Depth 10 | Out-File .\config.json 

# Downloading AppScan Presence
$asocToken=$(Invoke-WebRequest -Method "POST" -Headers @{"Accept"="application/json"} -ContentType 'application/json' -Body "{`"keyId`": `"$asocApiKeyId`",`"keySecret`": `"$asocApiKeySecret`"}" -Uri 'https://cloud.appscan.com/api/V2/Account/ApiKeyLogin' -SkipCertificateCheck | Select-Object -Expand Content | ConvertFrom-Json | select -ExpandProperty Token);
Remove-Item *AppScanPresence* -Force -Recurse
Invoke-WebRequest -Method "POST" -Headers @{"Accept"="application/json";"Authorization"="Bearer $asocToken"} -ContentType 'application/json' https://cloud.appscan.com/api/v2/Presences/$presenceId/Download/Win_x86_64/v2 -outfile AppScanPresence.zip
Expand-Archive .\AppScanPresence.zip
Start-Process .\AppScanPresence\Presence.exe -PassThru -NoNewWindow

# Running Asoc Web Hook Proxy (Python Flask). Interface 127.0.0.1 port 5000
do{
	$env:FLASK_ENV='development'
	$env:FLASK_APP='asoc_webhook_proxy'
	$proc = Start-Process py -ArgumentList ' -m flask run --host=127.0.0.1 --port=5000 --no-reload' -PassThru -NoNewWindow
	Start-Sleep -seconds 3600
	$proc | Stop-Process
}while ($true)
