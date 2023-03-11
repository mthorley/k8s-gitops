
MQTT bootstrap options - chose option 1 - [README.md](/apps/common/mqtt/README.md)

# Create password file

mosquitto_passwd [ -H hash ] [ -c | -D ] passwordfile username
mosquitto_passwd [ -H hash ] -b passwordfile username password
mosquitto_passwd -U passwordfile


# Options

## 1. Custom init container

Read secrets from vault
Run mosquitto_passwd to capture secrets and create password file
Link to password from configmap

- Script would need to run vault sdk or client
- Changes require a restart of the container

### 1.1 Concatenate environment variable as user:pwd
<code>

    TF_VAR_MQTT_CREDS=(user1 pwd1 \
        user2 pwd2 \
        user3 pwd3 \
        user4 pwd4)

    TF_VAR_MQTT_CREDS=$( IFS=:; printf '%s' "${MQTT_CREDS[*]}" )

    export TF_VAR_MQTT_CREDS
</code>

## 2. Store password file in vault

Setup script to run mosquitto_passwd to read secrets from env and create password file
Store password file in vault
Pull file from vault via external-secrets-operator

- How can a file be stored in vault and pulled as a k8s secret?
- Changes will be automatically sync'd

## 3. Use a security plugin for mqtt

? 

- What sec plugins exist?
- Could write custom plugin https://github.com/iegomez/mosquitto-go-auth#testing-custom that connects to vault.

## 4. Use vault agent as init container

- vault agent template generates passwordfile (creds in cleartext)
- invoke: mosquitto_passwd -U passwordfile to hash the file





