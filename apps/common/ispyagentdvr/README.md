
docker run -d --name=AgentDVR1 -e PUID=1000 -e PGID=1000 -e TZ=America/New_York -p 8090:8090 -p 3478:3478/udp -p 50000-50010:50000-50010/udp -v /tmp/AgentDVR/config/:/AgentDVR/Media/XML/ -v /tmp/AgentDVR/media/:/AgentDVR/Media/WebServerRoot/Media/ -v /tmp/AgentDVR/commands:/AgentDVR/Commands/ --restart unless-stopped mekayelanik/ispyagentdvr:latest

