# ccm (TLS Certificate/Compliance Monitor)

Ported from `../ccm` (the `k8s/` manifests in that project). Runs a scheduled
TLS endpoint checker (`CronJob` + CEL policies from `configmap-policies.yaml`
against endpoints in `configmap-endpoints.yaml`), an on-demand HTTP API for
the same scan, and an OTEL trace pipeline that feeds scan results into a
Neo4j graph via `tls-graph-adapter`.

Not yet wired into `apps/staging` or `apps/production`, and — because it
now pulls in `components/secrets-eso-vault`, which relies on Flux's
`postBuild.substitute` to fill in `${APP}` — it can't just be added to the
generic bundled kustomization there like `pi-temp-agent`/`mqtt` are.
It needs the same treatment as `torrent`/`node-red`/`node-red-dev`:

- a thin per-env overlay (e.g. `apps/production/ccm/kustomization.yaml`
  with `resources: [../../common/ccm]`)
- its own Flux `Kustomization` under `clusters/<env>/ccm.yaml`, with
  `postBuild.substitute.APP: "ccm"` (see `clusters/production/torrent.yaml`
  for the shape)

## Review notes / before enabling

- **Secrets now come from the shared cluster Vault** via
  `components/secrets-eso-vault` (added to `kustomization.yaml`, alongside
  a `serviceaccount.yaml` named `ccm` that the component's token `Secret`
  attaches to) instead of the dev-only `vault.yaml` that used to ship here.
  `setup/vault/kv2.tf` provisions the Vault side: a `ccm-secrets-role`
  Kubernetes-auth role/policy bound to the `ccm` SA/namespace, and a
  `secret/ccm` KV entry with `username`/`password` (from the
  `NEO4J_USERNAME`/`NEO4J_PASSWORD` Terraform variables) plus a derived
  `auth` key (`"${username}/${password}"`) for `neo4j.yaml`'s `NEO4J_AUTH`
  — so the two can't drift, unlike the old hand-seeded dev Vault. Set
  `TF_VAR_NEO4J_USERNAME`/`TF_VAR_NEO4J_PASSWORD` (placeholders already
  added to `.env`) and `terraform apply` in `setup/vault` before enabling
  this app.
- **No NetworkPolicy yet.** Every other app here (`crypto-automation`,
  `homeassistant`, `unifi-controller`, `node-red`) ships Cilium
  `deny-all-egress` + explicit allow rules. This app's job is to make
  arbitrary outbound TLS connections to whatever's in
  `configmap-endpoints.yaml`, so the usual "allow specific FQDN/CIDR"
  pattern doesn't fit cleanly — needs a deliberate policy (e.g. deny-all +
  allow DNS + allow egress on `443` only) rather than a copy-paste of an
  existing app's netpol.
- **`configmap-endpoints.yaml` ships with placeholder endpoints**
  (`example.com`, `www.python.org`) — replace with the real list to
  monitor.
- **Image tags are `:latest`** (`mthorley/tls-scanner`,
  `mthorley/tls-graph-adapter`), and pull policy is inconsistent: the
  `CronJob` has no `imagePullPolicy` set (so Kubernetes defaults to
  `Always` for a `:latest` tag and re-pulls every run), while the API
  `Deployment` explicitly sets `IfNotPresent` (so it won't pick up a new
  `:latest` push once a pod is running). Worth pinning to real tags.
- Both PVCs (Neo4j's `data` volume in `neo4j.yaml`, `10Gi`; the OTEL
  collector's `tls-scanner-otel-storage` in `otel-collector.yaml`, `1Gi`)
  pin `storageClassName: managed-nfs-storage`, matching every other app
  here — the cluster has no default `StorageClass`, so an unset one would
  never bind.

## Layout

- `namespace.yaml` — the `ccm` namespace.
- `serviceaccount.yaml` — `ccm` ServiceAccount that
  `components/secrets-eso-vault` issues a long-lived token `Secret` for.
- `configmap-endpoints.yaml` / `configmap-policies.yaml` — FQDN list and
  CEL policies for the scanner.
- `cronjob.yaml` — runs the checker every 10 minutes.
- `deployment.yaml` — `tls-scanner-api` (on-demand scan over HTTP) + its
  Service.
- `otel-collector.yaml` / `otel-collector-config.yaml` — OTLP collector
  that routes scan traces to Tempo and to `tls-graph-adapter`.
- `tls-graph-adapter.yaml` — OTLP → Neo4j adapter.
- `neo4j.yaml` — single-node Neo4j StatefulSet backing the graph. Reads
  `secret-ccm` (from `components/secrets-eso-vault`, see notes above).
