# kube-prometheus-stack

Replaces the 2020 jsonnet-generated stack in [../monitoring](../monitoring)
(prometheus-operator v0.40, prometheus v2.19, kube-state-metrics v1.9,
node-exporter v0.18, `carlosedp/*` ARM forks with kube-rbac-proxy sidecars)
with the upstream Helm chart. Currently used by staging only; production still
runs `../monitoring`.

What the chart provides: prometheus-operator + CRDs, prometheus, alertmanager,
grafana (with dashboard/datasource sidecars and the current kubernetes-mixin
dashboards), kube-state-metrics, node-exporter, the mixin alert rules,
ServiceMonitors for apiserver / kubelet / coredns / controller-manager /
scheduler / etcd, and the three ingresses.

Added here: a letsencrypt certificate for the ingresses via
`components/pki-certman-letsencrypt` (APP=grafana, extended to the prometheus
and alertmanager hostnames), the `prometheus-k8s` / `alertmanager-main` shim
services, and the dashboards in `dashboards/`.

What stays from `../monitoring` (see
[infrastructure/staging/monitoring](../../staging/monitoring/kustomization.yaml)):
the `grafana-storage` PVC (grafana's sqlite), the `grafana` ServiceAccount
(vault SecretStore token), prometheus-adapter, metallb ServiceMonitor.

This directory needs its own flux Kustomization
([clusters/staging/monitoring.yaml](../../../clusters/staging/monitoring.yaml))
because the component's `${APP}` / `${ACME_EMAIL}` are per-Kustomization
substitutions. Vault must hold
`secret/grafana-cf-api-token` (setup/vault/grafana-kv2.tf).

## Node prerequisites (kubeadm control plane)

The static pods bind to `127.0.0.1` by default, so the control-plane scrapes
report `TargetDown` / `Kube*Down` until the node is changed. On each
control-plane node edit `/etc/kubernetes/manifests/`:

| file | change |
|---|---|
| `kube-controller-manager.yaml` | `--bind-address=127.0.0.1` → `--bind-address=0.0.0.0` |
| `kube-scheduler.yaml` | `--bind-address=127.0.0.1` → `--bind-address=0.0.0.0` |
| `etcd.yaml` | `--listen-metrics-urls=http://127.0.0.1:2381` → `--listen-metrics-urls=http://127.0.0.1:2381,http://<node ip>:2381` (not `0.0.0.0`: it double-binds the port with the loopback listener and etcd crash-loops) |

kubelet restarts each static pod when its manifest changes. No IP needs
configuring: the chart's kube-system Services select the static pods by their
`component=` label and, being hostNetwork, they resolve to the node IP(s).
Restarting etcd takes the API server down for about a minute; do it when
nothing else is being rolled out.

kube-proxy is not scraped (`kubeProxy.enabled: false`): it also binds
`127.0.0.1` and cilium is the intended replacement.

## Cutover notes (how staging was migrated)

1. The old CRDs are in the `infrastructure` flux inventory. Before removing
   `../monitoring/setup` from a cluster, annotate them so prune leaves them for
   the chart to take over (otherwise every ServiceMonitor/Prometheus in the
   cluster is cascade-deleted):
   `kubectl annotate crd alertmanagers.monitoring.coreos.com podmonitors.monitoring.coreos.com prometheuses.monitoring.coreos.com prometheusrules.monitoring.coreos.com servicemonitors.monitoring.coreos.com thanosrulers.monitoring.coreos.com kustomize.toolkit.fluxcd.io/prune=disabled`
2. `namespace.yaml` and `services.yaml` re-declare objects from `../monitoring`
   under the same names so they are updated rather than pruned.
3. After the cutover delete the old PVC `prometheus-k8s-db-prometheus-k8s-0`
   in `monitoring`; the chart's prometheus uses a new one.
4. `arm-exporter` is gone; SoC temperature is `node_thermal_zone_temp` from
   node-exporter.

## Dashboards and datasources

`dashboards/*.json` and `datasources/*.yaml` are packaged as ConfigMaps
(labels `grafana_dashboard: "1"` / `grafana_datasource: "1"`, annotation
`grafana_folder` = folder) and provisioned by the grafana sidecars, which watch
every namespace - an app can ship its own next to its manifests (see
`victoria-metrics/grafana-datasource.yaml`). Grafana UI edits to provisioned
dashboards are not persisted: change the JSON (export from the UI, paste,
keep the `uid`).

The ConfigMaps carry `kustomize.toolkit.fluxcd.io/substitute: disabled` so
flux leaves grafana's `${var}` references alone.

| folder | dashboard | source |
|---|---|---|
| Cluster | App Health (`app-health`) | built here: alerts, per-namespace app health, nodes, NFS, prometheus self-health |
| Cluster | Kubernetes cluster monitoring (via Prometheus) (`Xjag-X7vk`) | the grafana.com #315 summary from the old stack; temperature panel moved to `node_thermal_zone_temp`, cAdvisor `pod_name` labels updated |
| Home | Power, Tasmota, Rack Controller Temperatures | moved from setup/monitoring (terraform) |
| Security | Falco Events, Cloudflare Tunnels | moved from setup/monitoring (terraform) |

Datasources: InfluxDB x4 and Loki with the same uids as
`setup/monitoring/grafana-datasource.tf`, Prometheus/Alertmanager from the
chart, VictoriaMetrics from its own directory. Rack Controller's prometheus
panel was repointed from the old auto-generated datasource uid to `prometheus`.

Not carried over: Network Logs (terraform, `setup/monitoring`) and the
hand-imported Trivy Operator dashboard.

`setup/monitoring` terraform still applies the same JSON files and
datasources to production until it is promoted; then the `grafana_dashboard`
and `grafana_data_source` resources go. Not yet gitops: the `Security` alert
rule group in `grafana-alerts.tf` (chart supports `sidecar.alerts` for
file-provisioned alert rules) and the `terraform` / `grafana-mcp` service
accounts, which have to be recreated on the new instance.

## Grafana

Chart grafana on its own PVC, i.e. a fresh instance; the pre-chart grafana
(`grafana-storage` PVC) is decommissioned rather than migrated. Nothing of
value lives in its sqlite on staging: dashboards and datasources are
provisioned by the sidecars, and setup/monitoring terraform re-applies its
dashboards / datasources / alert rules to whichever grafana `GRAFANA_URL`
points at.

- Admin password: generated by the chart into secret
  `kube-prometheus-stack-grafana` (`admin-user` / `admin-password`);
  `kubectl -n monitoring get secret kube-prometheus-stack-grafana -o jsonpath='{.data.admin-password}' | base64 -d`.
  Move it to vault via `grafana.admin.existingSecret` when convenient.
- The sidecar provisions `Prometheus` (uid `prometheus`), `Alertmanager` and
  any `grafana_datasource`-labelled ConfigMap (victoria-metrics ships one).
- `grafana.ini` holds nothing secret on staging (login form, SMTP). Prod's OAuth
  block needs the client secret supplied as `GF_AUTH_GENERIC_OAUTH_CLIENT_SECRET`
  via `envFromSecret` rather than the vault-templated ini file.

## Cutover 2: grafana into the chart + own flux Kustomization (staging)

The `infrastructure` Kustomization must not reconcile the new revision before
the new `monitoring` Kustomization has applied, or it prunes the `monitoring`
namespace (which moves between them) and everything in it.

1. `terraform apply` in setup/vault (adds `secret/grafana-cf-api-token` and the
   policy path) so the component's ExternalSecret resolves.
2. `flux suspend kustomization infrastructure`.
3. Push. The `monitoring` Kustomization is created, applies the composition
   (re-labelling the moved objects as its own) and upgrades the HelmRelease;
   chart grafana starts on a new PVC. Both ingresses claim `grafana.${domain}`
   for a few minutes; ingress-nginx keeps serving the older one until it goes.
4. `flux resume kustomization infrastructure`. Its prune removes the old grafana
   Deployment/Service/ConfigMaps/Secret/ServiceMonitor, the old ingresses and
   the vault-issuer Certificate/Issuer; objects now labelled as owned by
   `monitoring` are skipped.
5. Check `kubectl -n monitoring get certificate,ingress,pvc`, log in with the
   generated admin password, confirm the Cluster folder and datasources.
6. Decommission: drop `grafana-storage.yaml` from the staging composition
   (flux deletes the old PVC), delete PVC `prometheus-k8s-db-prometheus-k8s-0`
   and secret `domain-tls`. Recreate the `terraform` / `grafana-mcp` service
   accounts if staging needs them.

## Promoting to production

Create `clusters/production/monitoring.yaml` (APP, ACME_EMAIL) and `infrastructure/production/monitoring/kustomization.yaml`
from the staging ones, remove `../common/monitoring/setup` +
`../common/monitoring` and the grafana/issuer patches from
`infrastructure/production/kustomization.yaml`, add the OAuth env secret for
grafana, then follow both cutover sections. Once both clusters run this, `../monitoring` can be reduced to just the
grafana / adapter / ingress files.
