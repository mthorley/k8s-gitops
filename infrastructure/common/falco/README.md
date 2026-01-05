helm repo add falcosecurity https://falcosecurity.github.io/charts
helm repo update

helm template falco falcosecurity/falco \
  -n falco \
  -f values.yaml \
  > falco-stack.yaml
