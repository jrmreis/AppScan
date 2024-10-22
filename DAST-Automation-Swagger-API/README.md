# DAST Scan (AppScan on Cloud) Automation in Swagger API (OAS 2 and 3)
<br>
Using this script, you can create a Automation where there is a API Swagger (Open API Spec 2 and 3) and there is the Swagger properties file. We get Swagger properties file and convert it using openapi2postmanv2 (https://github.com/postmanlabs/openapi-to-postman) to a Collection File and run the API calls (endpoint) with Newman (https://github.com/postmanlabs/newman).<br>
<br>
We can do that inside a Container image or through a Bash Script and upload to ASoC start the scan.<br>
<br>
Steps after instantiate the container image:<br>
1 - Download json swagger<br>
2 - Convert json swagger to postman collection<br>
3 - Start the proxy server<br>
4 - Run newmann against collection<br>
5 - Stop proxy<br>
6 - Get manual explorer file from proxy server<br>
7 - Upload to asoc manual explorer file and scan template (scantdomfilteringfalse.scant)<br>
8 - Start scan<br>
9 - Wait scan finish<br>
10 - Get report<br>
<br>
Project files:<br>
Dockerfile - create a image containing all tools to run automation. Tools: nodejs, npm, unzip, curl, HCL TrafficRecorder (proxy server), openapi2postmanv2, jq and newman.<br>
scantdomfilteringfalse.scant - scan template file created with AppScan Standard (dom filtering disabled, login authentication disabled and no optimization set)<br>
script.sh - bash script file to run automation.<br>
<br>
Docker commands:<br>
docker build -t hclserverproxy .<br>
docker run --name hclserverproxy -d hclserverproxy<br>
docker exec -it hclserverproxy /bin/bash<br>
docker stop hclserverproxy<br>
docker rm hclserverproxy<br>
docker rmi hclserverproxy<br>
