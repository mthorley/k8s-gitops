
# Boostraping of MQTT credentials

Uses an initcontainer to invoke a bootstrap script (mounted via configMap) that reads from a k8s secrets which is pushed as the environment variable: `MQTT_CREDS`. The environment variable is `:` separated by `username:password` for each MQTT user. 

The bootstrap script reads the environment variable, parses the tokens and executes the `mosquitto_passwd` command for each user. This in turn, gets hashed into the credentials file `mosquitto/data/users.txt`.

The script is constrained to execute on the ash shell (mosquitto is based on busybox) and hence IFS (Internal Field Separator) does not operate in the same way as on Bash. This actually makes the shell script simpler.

The container will not start until the secret is mounted via the secrets operator and hence the environment variable will also be ready before the initContainer.

The configmap-boostrap.yaml ensure that Flux does not substitute variables (which breaks the resulting script structure) by using the annotation `kustomize.toolkit.fluxcd.io/substitute: disabled`

Alternatives considered including using a custom plugin for MQTT authnentication/authorisation but this was deemed the simplest.
