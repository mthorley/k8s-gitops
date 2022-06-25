
helm repo add external-secrets https://charts.external-secrets.io

helm template external-secrets external-secrets/external-secrets -n external-secrets --create-namespace  --set installCRDs=true > external-secrets-stack.yaml
