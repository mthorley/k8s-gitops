
```
helm repo add jetstack https://charts.jetstack.io

helm template \
  cert-manager jetstack/cert-manager \
  --namespace cert-manager \
  --create-namespace \
  --version v1.8.2 \
  --set installCRDs=true > certmanager-stack.yaml
```
