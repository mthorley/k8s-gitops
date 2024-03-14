

helm repo add neuvector https://neuvector.github.io/neuvector-helm/

helm template neuvector --namespace neuvector --create-namespace neuvector/core > neuvector-core-stack.yaml
helm template neuvector --namespace neuvector --create-namespace neuvector/crd > neuvector-crd-stack.yaml
helm template neuvector --namespace neuvector --create-namespace neuvector/monitor > neuvector-monitor-stack.yaml

## Diagnostics

### Unable to access manager - connection reset by peer

No known solution.
