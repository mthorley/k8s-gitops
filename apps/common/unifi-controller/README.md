Derived from

```
helm repo add k8s-at-home https://k8s-at-home.com/charts/
helm repo update
helm template unifi k8s-at-home/unifi -f values.yaml > unifi-stack.yaml
```

and extended by

https://flores.eken.nl/running-unifi-controller-on-k8s/