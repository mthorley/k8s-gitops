helm repo add grafana https://grafana.github.io/helm-charts
helm repo update

helm template loki grafana/loki -f values.yaml > loki-stack.yaml

curl -v -H "Content-Type: application/json" -XPOST -s "http://loki.loki:3100/loki/api/v1/push" --data-raw \
  '{"streams": [{ "stream": { "foo": "bar2" }, "values": [ [ "1649677555000000000", "fizzbuzz" ] ] }]}'