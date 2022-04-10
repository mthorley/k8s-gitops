helm repo add vector https://helm.vector.dev
helm repo update

helm template vector vector/vector -f values.yaml> vector-stack.yaml
