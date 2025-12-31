
```
helm repo add jetstack https://charts.jetstack.io

helm template \
  cert-manager jetstack/cert-manager \
  --namespace cert-manager \
  --version v1.19.2 \
  --create-namespace \
  --set startupapicheck.timeout=5m \
  --set global.leaderElection.namespace=cert-manager \
  --set installCRDs=true > certmanager-stack.yaml
```
