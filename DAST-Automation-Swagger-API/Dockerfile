FROM node:latest
RUN apt update
RUN apt install -y curl unzip jq && apt clean
RUN mkdir TrafficRecorder && cd TrafficRecorder && curl https://cloud.appscan.com/api/V2/Tools/TrafficRecorder/linux_x64 -o TrafficRecorder.Linux.zip
RUN cd TrafficRecorder && unzip TrafficRecorder.Linux.zip; exit 0
RUN chmod +x /TrafficRecorder/java/bin/java
RUN npm i -g openapi-to-postmanv2
RUN npm set strict-ssl false && npm install -g newman
COPY scantdomfilteringfalse.scant /TrafficRecorder
# ENTRYPOINT ["tail", "-f", "/dev/null"]
