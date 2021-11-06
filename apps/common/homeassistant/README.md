
```
helm repo add k8s-at-home https://k8s-at-home.com/charts/
helm repo update
helm template home-assistant k8s-at-home/home-assistant -f values.yaml > home-assistant-stack.yaml

```