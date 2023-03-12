## Generate stack for k8s via Helm

Derived from

```
helm repo add k8s-at-home https://k8s-at-home.com/charts/
helm repo update
helm template zigbee2mqtt k8s-at-home/zigbee2mqtt -f values.yaml > stack.yaml
```

## Ensure nodeaffinity established 

Label node for affinity

`kubectl label nodes rpi-kube-worker-stg-03 app=zigbee-controller`

Verify labels across nodes

`kubectl get nodes --show-labels`

## Environment convention for secrets

As per https://www.zigbee2mqtt.io/guide/configuration/#environment-variables, `ZIGBEE2MQTT_CONFIG_MQTT_USER` and `ZIGBEE2MQTT_CONFIG_MQTT_PASSWORD` maps to mqtt user and password respectively.
