
helm repo add cilium https://helm.cilium.io
helm repo update
helm template tetragon cilium/tetragon -n kube-system > tetragon-stack.yaml

