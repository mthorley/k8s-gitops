# kube-prometheus-stack

Replaces the 2020 jsonnet-generated stack in [../monitoring](../monitoring)
(prometheus-operator v0.40, prometheus v2.19, kube-state-metrics v1.9,
node-exporter v0.18, `carlosedp/*` ARM forks with kube-rbac-proxy sidecars)
with the upstream Helm chart. Currently used by staging only; production still
runs `../monitoring`.

What the chart provides: prometheus-operator + CRDs, prometheus, alertmanager,
kube-state-metrics, node-exporter, the kubernetes-mixin alert rules and
ServiceMonitors for apiserver / kubelet / coredns / controller-manager /
scheduler / etcd.

What stays from `../monitoring` (see
[infrastructure/staging/monitoring](../../staging/monitoring/kustomization.yaml)):
grafana, ingresses + cert, prometheus-adapter, metallb ServiceMonitor.

## Node prerequisites (kubeadm control plane)

The static pods bind to `127.0.0.1` by default, so the control-plane scrapes
report `TargetDown` / `Kube*Down` until the node is changed. On each
control-plane node edit `/etc/kubernetes/manifests/`:

| file | change |
|---|---|
| `kube-controller-manager.yaml` | `--bind-address=127.0.0.1` → `--bind-address=0.0.0.0` |
| `kube-scheduler.yaml` | `--bind-address=127.0.0.1` → `--bind-address=0.0.0.0` |
| `etcd.yaml` | `--listen-metrics-urls=http://127.0.0.1:2381` → `--listen-metrics-urls=http://127.0.0.1:2381,http://<node ip>:2381` (not `0.0.0.0`: it double-binds the port with the loopback listener and etcd crash-loops) |

kubelet restarts each static pod when its manifest changes. The node IP is
`${controlplane_ip}`, substituted by the cluster's flux Kustomization.
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

## Promoting to production

Add `controlplane_ip` to `clusters/production/infrastructure.yaml`, create
`infrastructure/production/monitoring/kustomization.yaml` from the staging one
and swap `../common/monitoring/setup` + `../common/monitoring` for `monitoring`
in `infrastructure/production/kustomization.yaml`. Then follow the cutover
notes. Once both clusters run this, `../monitoring` can be reduced to just the
grafana / adapter / ingress files.
