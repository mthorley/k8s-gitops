helm repo add grafana https://grafana.github.io/helm-charts
helm repo update

helm template loki grafana/loki -f values.yaml > loki-stack.yaml

