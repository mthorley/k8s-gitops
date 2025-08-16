sudo security add-trusted-cert -d -r trustRoot -k /Library/Keychains/System.keychain root-ca.pem

sudo security import intermediate-ca.pem -k /Library/Keychains/System.keychain
