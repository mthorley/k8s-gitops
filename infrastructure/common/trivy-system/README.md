## Install
helm repo add aqua https://aquasecurity.github.io/helm-charts/
helm repo update


## Generate
helm template trivy-operator aqua/trivy-operator \
  --namespace trivy-system \
  --create-namespace \
  --set="trivy.ignoreUnfixed=true" > trivy-system-stack.yaml
