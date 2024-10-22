# Delete scans in ASoC
<br>
Connect to ASOC (AppScan on Cloud) get scanIds in a period of time and delete all scans keeping all issues.<br>
Before use, set variables ASOCkeyId and ASOCkeySecret. Jq is required.<br> 
<br>
How to use:<br>
./deleteScans.sh startDate endDate<br>
Example:<br>
./deleteScans.sh 2022-07-01 2022-07-31<br>
<br>
PS: Be careful using this script. Try on small periods before a deletion on larger periods.
