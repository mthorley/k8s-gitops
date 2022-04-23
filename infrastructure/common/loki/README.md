## Install
`helm repo add grafana https://grafana.github.io/helm-charts`

`helm repo update`

`helm template loki grafana/loki --namespace loki -f values.yaml > loki-stack.yaml`

## Insert log entry

Taken from https://grafana.com/docs/loki/latest/api/#examples-4

`curl -v -H "Content-Type: application/json" -XPOST -s "http://loki.loki:3100/loki/api/v1/push" --data-raw \
  '{"streams": [{ "stream": { "foo": "bar2" }, "values": [ [ "1649677555000000001", "fizzbuzz" ] ] }]}'
`
