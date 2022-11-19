
helm repo add bitnami https://charts.bitnami.com/bitnami

helm template grafana-operator bitnami/grafana-operator -n grafana --create-namespace > grafana-op-stack.yaml

