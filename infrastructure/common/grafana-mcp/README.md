
helm repo add grafana https://grafana.github.io/helm-charts
helm repo update
helm template grafana-mcp grafana/grafana-mcp --namespace grafana-mcp -f values.yaml > grafana-mcp-stack.yaml
