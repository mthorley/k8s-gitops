
```
helm repo add jetstack https://charts.jetstack.io

helm template \
  cert-manager jetstack/cert-manager \
  --namespace cert-manager \
  --create-namespace \
  --set startupapicheck.timeout=5m \
  --set global.leaderElection.namespace=cert-manager \
  --set installCRDs=true > certmanager-stack.yaml
```
