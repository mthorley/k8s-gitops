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
- **Image tags are `:latest`** (`mthorley/tls-scanner` for both the API
  `Deployment` and the `CronJob`, `mthorley/tls-graph-adapter`), so all
  three set `imagePullPolicy: Always`. They originally used
  `IfNotPresent`, which meant a rebuilt `:latest` was never picked up —
  the node keeps serving the image it already cached under that tag, and
  even deleting the pod doesn't help. That bit during the arm64 rebuild.
  Pinning real tags (or digests) would be better than `:latest` +
  `Always`, since `Always` re-pulls on every pod start and still gives no
  record of which build is running.
- **The cluster is arm64** (Raspberry Pi nodes), so these images must be
  built multi-arch or arm64 — an amd64-only image fails at runtime with
  `exec /usr/local/bin/uvicorn: exec format error`, not at pull time.
  Verify a push with
  `docker buildx imagetools inspect mthorley/tls-scanner:latest`
  (`docker manifest inspect` can't read OCI image indexes and will
  mislead you).
- Both PVCs (Neo4j's `data` volume in `neo4j.yaml`, `10Gi`; the OTEL
  collector's `tls-scanner-otel-storage` in `otel-collector.yaml`, `1Gi`)
  pin `storageClassName: managed-nfs-storage`, matching every other app
  here — the cluster has no default `StorageClass`, so an unset one would
  never bind.
- **Neo4j runs as uid/gid `7474` on NFS.** Its entrypoint `chown -R`s
  `/data` only when running as root, and the NFS export uses
  `root_squash`, so as root it dies with
  `chown: changing ownership of '/data/dbms': Operation not permitted`.
  Running as the image's own `neo4j` user skips the chown; the
  nfs-subdir provisioner creates volume dirs `0777` so it can still
  write. Note Neo4j does not officially support NFS for store files
  (locking/fsync semantics) — if the graph is ever more than a toy,
  move it to node-local storage (see `frigate/pv.yaml` for the
  `local-storage` pattern).
- **Neo4j sets `enableServiceLinks: false`.** Its Service is named
  `neo4j`, so Kubernetes injects service-link env vars such as
  `NEO4J_PORT_7687_TCP_PORT`, and the entrypoint turns every `NEO4J_*`
  env var into a config setting — producing
  `Unrecognized setting ... PORT.7687.TCP.PORT` and a crash loop. Don't
  remove this, and don't rename the Service to anything else starting
  with `neo4j` (the prefix is what triggers it).

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
- `loadbalancer.yaml` — `neo4j-public`, a MetalLB `LoadBalancer` exposing
  Bolt `7687` and the Browser UI `7474` on `${neo4j_ip}`
  (`192.168.2.21`, set in `clusters/production/ccm.yaml`).

## Remote access (Neo4j Desktop)

Connect Neo4j Desktop / cypher-shell to `bolt://192.168.2.21:7687`, or open
the Browser UI at `http://192.168.2.21:7474`. Credentials are whatever is
in Vault at `secret/ccm` (`username`/`password`).

This deliberately does **not** go through envoy-gateway. Bolt is a raw TCP
protocol, so a Gateway would need `TCPRoute`/`TLSRoute` — both
experimental-channel Gateway API resources, while
`infrastructure/common/gateway-api-crds` installs the standard channel
(v1.4.1). Exposing it with a `LoadBalancer` matches every other non-HTTP
service in this cluster (`mqtt` 1883, `influxdb` 8086, `node-red` syslog
514/UDP) and needs no cluster-wide CRD change. If Bolt ever has to be
routed through the gateway with a hostname and TLS, that means switching
`gateway-api-crds` to `experimental-install.yaml` — which replaces the
Gateway API CRDs for every gateway in the cluster.

Two caveats: the traffic is plain `bolt://` (auth still enforced, but
unencrypted) unless Neo4j is given its own certs for `bolt+s://`; and
`192.168.2.21` is a private MetalLB address, so this is LAN-only — it is
not reachable from the internet, which is the right default for a
database.
