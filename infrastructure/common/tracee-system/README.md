helm repo add aqua https://aquasecurity.github.io/helm-charts/
helm repo update
helm template tracee aqua/tracee --namespace tracee-system --include-crds > tracee-stack.yaml
