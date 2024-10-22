## Automation Import Scan Issues from ASOC to ASE

![image](https://user-images.githubusercontent.com/69405400/183989000-647f4ad5-d1d8-4c5e-bd46-4dec0dfc7527.png)


## Requirements
1 - AppScan Enterprise Server hostname<br>
2 - AppScan Enterprise key pair<br>
3 - AppScan on Cloud key pair<br>
4 - AppScan Presence<br>
5 - Python3 for Windows (Flask and requests)<br>
6 - Powershell 7.x<br>
<br>
Install Python modules<br>
```
py -m pip install Flask
py -m pip install requests
```
<br>
TO RUN: <br>
1 - Download the project<br>
2 - Change variable in the file startWebHookProxy.ps1:<br>
$asocApiKeyId='aaaaaaaaaaaaaaaaaaaaaaaaa'<br>
$asocApiKeySecret='aaaaaaaaaaaaaaaaaaaaaaaaa'<br>
$presenceId='aaaaaaaaaaaaaaaaaaaaaaaaa'<br>
$aseHostname='aaaaaaaaaaaaaaaaaaaaaaaaa'<br>
$aseApiKeyId='aaaaaaaaaaaaaaaaaaaaaaaaa'<br>
$aseApiKeySecret='aaaaaaaaaaaaaaaaaaaaaaaaa'<br>
3 - Execute .\startWebHookProxy.ps1.
