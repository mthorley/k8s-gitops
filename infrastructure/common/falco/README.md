helm repo add falcosecurity https://falcosecurity.github.io/charts
helm repo update

helm template falco falcosecurity/falco > falco-stack.yaml
