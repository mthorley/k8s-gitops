
# Vault Purpose

Vault is used to manage key value secrets and also pki.

## kv2 secrets

Refer to kv2.tf

## pki

pki.tf uses vault to generate an intermediate CA that can be used to manage TLS connections from clients as long as the intermediate CA is trusted. 

To trust the intermediateCA, the cert needs to be added as a trusted cert in chrome as follows:

1. Navigate to Chrome ... -> Settings -> Privacy and Security
2. Naviatge to security -> Manage Device Certificates

For macOS, this will open Keychain Access.

3. Add the intermediate CA to the login default keychain (authenticate where required)
4. Double click the imported cert, under the Trust chevron, select Always Trust "when using this certifcate"
5. Access the TLS endpoint and chrome should declare "Conection is secure"
