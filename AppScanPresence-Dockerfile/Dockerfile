FROM registry.access.redhat.com/ubi8/ubi:latest
LABEL description="AppScan Presence in Dockerfile for Linux Image"
ENV APIKEYID xxxxxxxxxxxxxxxxxxxxx
ENV APIKEYSECRET xxxxxxxxxxxxxxxxxxxxx
ENV PRESENCEID xxxxxxxxxxxxxxxxxxxxx
RUN yum install -y unzip && yum clean all
RUN curl -X POST --header 'Content-Type: application/json' --header 'Accept: application/json' -d '{"KeyId":"'"${APIKEYID}"'","KeySecret":"'"${APIKEYSECRET}"'"}' 'https://cloud.appscan.com/api/V2/Account/ApiKeyLogin' > /root/output.txt
RUN curl -X POST --header 'Accept: application/zip' --header 'Content-Length: 0' --header "Authorization: Bearer $(grep -oP '(?<="Token":")[^"]*' /root/output.txt)" https://cloud.appscan.com/api/v2/Presences/$PRESENCEID/Download/Linux_x86_64/v2 > /root/AppScanPresence-Linux_x86_64.zip
RUN mkdir /root/AppScanPresence/ && unzip /root/AppScanPresence-Linux_x86_64.zip -d /root/AppScanPresence/
ENTRYPOINT  ["sh","/root/AppScanPresence/startPresence.sh"]
