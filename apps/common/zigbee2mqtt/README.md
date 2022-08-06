


## Generate stack

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
