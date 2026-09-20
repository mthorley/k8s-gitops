# monitoring-system

The kube-prometheus-stack Helm chart plus the gateway, certificate,
dashboards and datasources that make up the monitoring stack. The Helm
release and its objects are still named `kube-prometheus-stack`; the
namespace is `monitoring`.

Replaces the 2020 jsonnet-generated stack in [../monitoring](../monitoring)
(prometheus-operator v0.40, prometheus v2.19, kube-state-metrics v1.9,
node-exporter v0.18, `carlosedp/*` ARM forks with kube-rbac-proxy sidecars)
with the upstream Helm chart. Currently used by staging only; production still
runs `../monitoring`.

What the chart provides: prometheus-operator + CRDs, prometheus, alertmanager,
grafana (with dashboard/datasource sidecars and the current kubernetes-mixin
dashboards), kube-state-metrics, node-exporter, the mixin alert rules and
ServiceMonitors for apiserver / kubelet / coredns / controller-manager /
scheduler / etcd.

Added here: `gateway.yaml` exposing grafana / prometheus / alertmanager through
envoy-gateway on one Gateway (external-dns registers the hostnames from the
HTTPRoutes), a letsencrypt certificate for it via
`components/pki-certman-letsencrypt` (APP=grafana, extended to the prometheus
and alertmanager hostnames), a PodMonitor for metallb, and the dashboards in
`dashboards/`. `metrics.k8s.io` comes from `../metrics-server` rather than the
old prometheus-adapter.

Vault access for the namespace (SecretStore, SA token) comes from
`components/secrets-eso-vault` with the `${APP}` ServiceAccount in
`serviceaccount.yaml`; it exists to feed the certificate's Cloudflare-token
ExternalSecret. (Its own `external-secret-grafana` -> `secret-grafana`, the
old grafana.ini, is unused by the chart grafana.)

Nothing is borrowed from `../monitoring` any more; the staging composition
([infrastructure/staging/monitoring](../../staging/monitoring/kustomization.yaml))
is just this directory.

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
2. `namespace.yaml` re-declares the namespace from `../monitoring` under the
   same name so it is updated rather than pruned.
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
| Home | Power, Tasmota, Rack Controller Temperatures | copies of the setup/monitoring (terraform) dashboards |
| Security | Falco Events, Cloudflare Tunnels | copies of the setup/monitoring (terraform) dashboards |

Datasources: InfluxDB x4 and Loki with the same uids as
`setup/monitoring/grafana-datasource.tf`, Prometheus/Alertmanager from the
chart, VictoriaMetrics from its own directory. Rack Controller's prometheus
panel was repointed from the old auto-generated datasource uid to `prometheus`.

Not carried over: Network Logs (terraform, `setup/monitoring`) and the
hand-imported Trivy Operator dashboard.

`setup/monitoring` terraform is the old stack's (production's) copy of the
same dashboards and datasources and is left untouched; it retires when
production is promoted. Not yet gitops: the `Security` alert
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
3. Push. `dependsOn: infrastructure` blocks `monitoring` while
   `infrastructure` is suspended at the old revision, so drop it in-cluster
   for the first apply (`kubectl -n flux-system patch kustomization monitoring
   --type json -p '[{"op":"remove","path":"/spec/dependsOn"}]'`; flux-system
   restores it from git). The composition applies (re-labelling the moved
   objects as its own) and the HelmRelease upgrades; chart grafana starts on
   a new PVC.
4. `flux resume kustomization infrastructure`. Its prune removes the old grafana
   Deployment/Service/ConfigMaps/Secret/ServiceMonitor, the old ingresses and
   the vault-issuer Certificate/Issuer; objects now labelled as owned by
   `monitoring` are skipped. (When the chart still rendered ingresses, the
   ingress-nginx admission webhook rejected them until this prune ran.)
5. DNS: external-dns only manages records carrying its ownership TXT. Delete
   any hand-made UniFi record for `grafana.${domain}` (it pointed at
   ingress-nginx) so the Gateway's record can be created.
6. Check `kubectl -n monitoring get certificate,gateway,httproute,pvc`, log in
   with the generated admin password, confirm the Cluster folder and
   datasources.
7. Decommission (done on staging): `grafana-storage.yaml` dropped from the
   composition (flux deletes the old PVC); PVC
   `prometheus-k8s-db-prometheus-k8s-0` and secret `domain-tls` deleted by
   hand. Recreate the `terraform` / `grafana-mcp` service accounts if needed.

## Promoting to production

Create `clusters/production/monitoring.yaml` (APP, ACME_EMAIL) and `infrastructure/production/monitoring/kustomization.yaml`
from the staging ones, remove `../common/monitoring/setup` +
`../common/monitoring` and the grafana/issuer patches from
`infrastructure/production/kustomization.yaml`, add the OAuth env secret for
grafana, then follow both cutover sections. Once both clusters run this, `../monitoring` can be reduced to just the
grafana / adapter / ingress files.
