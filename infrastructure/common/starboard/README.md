
```
helm repo add aqua https://aquasecurity.github.io/helm-charts/
helm repo update

helm template starboard-operator aqua/starboard-operator \
  --namespace starboard-system \
  --create-namespace \
  --set="trivy.ignoreUnfixed=true" \
  --version 0.10.12 > starboard-stack.yaml
```
