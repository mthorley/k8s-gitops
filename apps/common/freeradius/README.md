
# Docker

Dockerfile extended from https://github.com/tgbyte/docker-freeradius/blob/master/Dockerfile
under https://github.com/mthorley/container-images/tree/main/apps/freeradius 

# Testing

`radtest -x bob bob 192.168.3.25:1812 0 sharedSecret`

should return

    Sent Access-Request Id 225 from 0.0.0.0:54456 to 192.168.3.25:1812 length 73
	User-Name = "bob"
	User-Password = "bob"
	NAS-IP-Address = 127.0.1.1
	NAS-Port = 0
	Message-Authenticator = 0x00
	Cleartext-Password = "bob"
    Received Access-Accept Id 225 from 192.168.3.25:1812 to 172.16.115.137:54456 length 20
