## VictoriaMetrics

Single-node [VictoriaMetrics](https://docs.victoriametrics.com/victoriametrics/single-server-victoriametrics/) deployed via a Flux `HelmRelease` of the
[victoria-metrics-single](https://github.com/VictoriaMetrics/helm-charts/tree/master/charts/victoria-metrics-single) chart.

Intended as long-term storage for Prometheus metrics (via `remoteWrite`) and a Grafana datasource.

* UI / API: `https://victoria-metrics.${domain}` (vmui at `/vmui`) via envoy-gateway (gateway.yaml)
* In-cluster: `http://victoria-metrics-victoria-metrics-single-server.victoria-metrics:8428`
* Prometheus remote write endpoint: `.../api/v1/write`
* Data on `managed-nfs-storage`, 12 month retention

### Prerequisites

Vault needs the `victoria-metrics-secrets-role` k8s auth role and the
`victoria-metrics-cf-api-token` KV entry for the Let's Encrypt DNS-01 solver -
both defined in `setup/vault/kv2.tf` (same shape as adguard: cert only, no
app-level secret).

### Migrating InfluxDB data

`migrate-influx-job.yaml` runs [vmctl](https://docs.victoriametrics.com/victoriametrics/vmctl/influxdb/)
against `influxdb.influxdb:8086` and imports one database into VM. It is a
manual, run-once-per-database step (not managed by Flux):

```
influx -host <influxdb_ip> -execute 'SHOW DATABASES'          # pick a db
sed 's/CHANGEME/<db>/' migrate-influx-job.yaml | kubectl create -f -
kubectl -n victoria-metrics logs -f job/migrate-influx
kubectl -n victoria-metrics delete job migrate-influx           # before the next db
```

Naming: `foo,tag1=v field1=12` in db `iot` becomes `foo_field1{tag1="v",db="iot"}`.
Grafana panels need rewriting from InfluxQL to MetricsQL against a
Prometheus/VictoriaMetrics datasource, e.g.

```
SELECT mean("temp") FROM "sensors" WHERE "room"='study' GROUP BY time($__interval)
  -> avg_over_time(sensors_temp{db="iot",room="study"}[$__interval])
```

Re-running for the same db is safe (VM dedups identical samples), so the
migration can be repeated just before cutting Node-RED over to write to VM.

### Upgrade

`helm repo add vm https://victoriametrics.github.io/helm-charts/`

`helm search repo vm/victoria-metrics-single`

Bump `spec.chart.spec.version` in `helmrelease.yaml`.
