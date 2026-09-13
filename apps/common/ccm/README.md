# ccm

TLS endpoint compliance monitoring, ported from the `../ccm` project
("Kubernetes TLS Endpoint Checker" — the `CCM-TLS-*` policy IDs are where
the directory name comes from; the project never expands the acronym).

Each endpoint in `configmap-endpoints.yaml` is probed on port 443 with
sslyze, and the result is evaluated against the CEL policies in
`configmap-policies.yaml` (`pass`/`warn`/`fail`). Results are emitted as
OTEL spans and persisted as a graph:

```
CronJob (*/10 min) ┐
                   ├─> otel-collector:4317 ─> tls-graph-adapter:4318 ─> neo4j:7687
tls-scanner-api ───┘        (OTLP gRPC)            (OTLP HTTP)             (Bolt)
  POST /scan                                                                 │
                                                            ccm-dashboard <──┘
```

The graph holds `ScanRun`, `Endpoint` and `Certificate` nodes joined by
`CHECKED` and `PRESENTED` (plus `Policy`/`EVALUATED_BY`/`PRODUCED`, which
only appear when a policy actually matches — an all-`pass` scan writes
none).

## Deployment wiring

Production only: `clusters/production/ccm.yaml` → `apps/production/ccm`
(a thin overlay) → here. There is no staging equivalent.

It **cannot** be added to the bundled `apps/production/kustomization.yaml`
like `pi-temp-agent`/`mqtt` are, because both components below depend on
Flux `postBuild.substitute` for `${APP}`, which plain kustomize leaves as a
literal. Hence the dedicated Flux `Kustomization`, same as
`torrent`/`node-red`/`adguard`.

`clusters/production/ccm.yaml` must supply:

| Substitution | Used by |
| --- | --- |
| `APP: "ccm"` | both components — secret names, Vault paths, `ccm-secrets-role`, cert name, `ccm.${domain}` |
| `ACME_EMAIL` | the letsencrypt component's ACME `Issuer` |
| `neo4j_ip` | `loadbalancer.yaml` — the MetalLB address for Bolt/Browser |
| `domain` | from the `cluster-vars` Secret |

and `dependsOn: infrastructure, gateway-api-crds, envoy-gateway` (the last
two because of `gateway.yaml`).

Components: `secrets-eso-vault` (SecretStore + `secret-ccm` +
`serviceaccount.yaml`'s token) and `pki-certman-letsencrypt` (the
dashboard's TLS cert).

### Vault prerequisites

`setup/vault/kv2.tf` provisions these; `terraform apply` in `setup/vault`
before first deploy, or the ExternalSecrets fail and cert issuance stalls.

- `ccm-secrets-role` — Kubernetes-auth role bound to the `ccm` SA in the
  `ccm` namespace, with read on both paths below.
- `secret/ccm` — `username`, `password`, and a derived
  `auth` (`"<username>/<password>"`) for `neo4j.yaml`'s `NEO4J_AUTH`.
  Derived in Terraform so it cannot drift from the other two. Supplied via
  the `NEO4J_USERNAME` / `NEO4J_PASSWORD` Terraform variables — the username
  **must** be literally `neo4j`, the only admin name the Neo4j image's
  `NEO4J_AUTH` accepts.
- `secret/ccm-cf-api-token` — `dns-api-token` for the ACME DNS-01 solver.

## Access

- **Dashboard** — `https://ccm.${domain}` via `ccm-gateway`.
- **Neo4j Desktop / cypher-shell** — Bolt on `7687`, Browser UI on `7474`,
  at the `neo4j-public` address
  (`kubectl get svc neo4j-public -n ccm`). Credentials are `secret/ccm`.

Bolt is exposed by a MetalLB `LoadBalancer`, deliberately not the gateway:
it is raw TCP, so a Gateway would need `TCPRoute`/`TLSRoute` from the
**experimental** Gateway API channel, while
`infrastructure/common/gateway-api-crds` installs the standard channel
(v1.4.1). A `LoadBalancer` matches every other non-HTTP service here
(`mqtt` 1883, `influxdb` 8086, `node-red` syslog 514/UDP) and needs no
cluster-wide CRD change. Routing Bolt through the gateway would mean
switching to `experimental-install.yaml`, replacing the Gateway API CRDs
for every gateway in the cluster.

Both ports share one IP, so the Browser offers the correct Bolt URL with no
`advertised_address` override. Traffic is plain `bolt://` — authenticated
but unencrypted — unless Neo4j is given certs for `bolt+s://`. The IP is
private, so this is LAN-only, which is the right default for a database.

## Outstanding

- **No NetworkPolicy.** Every comparable app here (`crypto-automation`,
  `homeassistant`, `unifi-controller`, `node-red`) ships Cilium
  `deny-all-egress` plus explicit allows. This app's whole job is arbitrary
  outbound TLS to whatever is in `configmap-endpoints.yaml`, so the usual
  "allow these FQDNs/CIDRs" shape does not fit — it needs a deliberate
  policy (deny-all + DNS + egress on 443 only), not a copy-paste.
- **`configmap-endpoints.yaml` still holds placeholders** (`example.com`,
  `www.python.org`).
- Image tags are `:latest` with `imagePullPolicy: Always`. That works but
  records nothing about which build is running and re-pulls on every pod
  start; real tags or digests would be better.
- The scanner emits `tls.reachable`, `tls.hostname.verified`,
  `tls.certificate.valid` and `tls.error.category`, none of which the
  adapter writes to the graph — unused signal, not a fault.

## Do not undo these

Each of these was a crash loop or a silent data-loss bug. The symptom is
given so it is recognisable if it recurs.

- **Neo4j runs as uid/gid `7474`.** Its entrypoint `chown -R`s `/data` only
  as root, and the NFS export uses `root_squash`, so as root it dies with
  `chown: changing ownership of '/data/dbms': Operation not permitted`.
  Running as the image's own user skips the chown; the nfs-subdir
  provisioner creates dirs `0777` so it can still write.
- **Neo4j sets `enableServiceLinks: false`.** Its Service is named `neo4j`,
  so Kubernetes injects `NEO4J_PORT_7687_TCP_PORT` and friends, and the
  entrypoint turns every `NEO4J_*` env var into a config setting →
  `Unrecognized setting ... PORT.7687.TCP.PORT` and a crash loop. Do not
  rename the Service to anything else starting with `neo4j` either — the
  prefix is the trigger. `ccm-dashboard.yaml` sets it too, defensively.
- **The collector binds `0.0.0.0` explicitly.** Since collector v0.110 the
  OTLP receiver defaults to `localhost`, so upstream's empty `grpc:`/`http:`
  blocks made it reachable only inside its own pod: every sender got
  `connection refused` on `otel-collector:4317`, all spans were dropped,
  and the collector logged nothing at all.
- **The `CronJob` sets the OTEL env vars.** Upstream shipped no `env:`
  block, so the SDK fell back to `localhost:4317` and every scheduled
  scan's spans were dropped (`Transient error StatusCode.UNAVAILABLE ...
  localhost:4317`, then `Timeout was exceeded in force_flush()`) — while
  the job still exited 0 and looked healthy.
- **Both PVCs pin `storageClassName: managed-nfs-storage`.** The cluster
  has no default `StorageClass`, so an unset one never binds
  (`no persistent volumes available for this claim and no storage class is
  set`).
- **No `otlp/tempo` exporter.** No Tempo is deployed here; it failed
  forever (`lookup tempo ... no such host`) and, with `retry_on_failure`
  plus the persistent queue, would fill the 1Gi `file_storage` PVC with
  undeliverable spans. Re-add it — and put it back in the traces pipeline —
  only if Tempo lands.

## Operating notes

- **Editing `otel-collector-config.yaml` does not restart the collector.**
  The ConfigMap changes but the Deployment's pod template does not, so Flux
  will not roll it and the collector keeps its old config. Delete the
  `tls-scanner-otel` pod after a config change, or convert it to a kustomize
  `configMapGenerator`, whose name hash rolls the Deployment automatically.
- **The cluster is arm64** (Raspberry Pi). An amd64-only image pulls fine
  and then fails at runtime with
  `exec /usr/local/bin/uvicorn: exec format error`. Verify a push with
  `docker buildx imagetools inspect mthorley/tls-scanner:latest` —
  `docker manifest inspect` cannot read OCI image indexes and will report a
  multi-arch image as single-arch.
- **`:latest` + `imagePullPolicy: Always` still needs a pod delete** to
  pick up a rebuild, since Flux sees no pod-template change.
- Trigger a scan on demand without waiting for the CronJob:
  `kubectl exec -n ccm deploy/tls-scanner-api -- python -c "import
  urllib.request as u; print(u.urlopen(u.Request('http://localhost:8080/scan',
  method='POST'), timeout=280).read().decode())"`
- `otlphttp/graph-adapter` uses the exporter's default gzip, which requires
  the adapter to honour `Content-Encoding: gzip`. It did not originally, and
  the symptom is obscure: a protobuf `DecodeError` returned as HTTP 500,
  the collector logging `Permanent error ... HTTP Status Code 500` and
  dropping the batch, while the adapter logs only a bare access line
  (it re-raises as `HTTPException` without logging the cause). If that
  recurs, `compression: none` on the exporter is the quick workaround.

## Layout

- `namespace.yaml` — the `ccm` namespace.
- `serviceaccount.yaml` — `ccm` ServiceAccount; `secrets-eso-vault` issues
  its long-lived token `Secret`.
- `tls-scanner/` — scanner and telemetry path, with its own
  `kustomization.yaml` (referenced as `- tls-scanner`, the same arrangement
  as `node-red/netpol`):
  - `configmap-endpoints.yaml` / `configmap-policies.yaml` — FQDN list and
    CEL policies.
  - `cronjob.yaml` — runs the checker every 10 minutes.
  - `deployment.yaml` — `tls-scanner-api` (`POST /scan`) + its Service.
  - `otel-collector.yaml` / `otel-collector-config.yaml` — OTLP collector
    forwarding scan traces to `tls-graph-adapter`.
  - `tls-graph-adapter.yaml` — OTLP → Neo4j adapter.
- `neo4j.yaml` — single-node Neo4j StatefulSet, reads `secret-ccm`.
- `loadbalancer.yaml` — `neo4j-public`, MetalLB Service exposing Bolt 7687
  and Browser 7474 on `${neo4j_ip}`.
- `ccm-dashboard.yaml` — dashboard Deployment + ClusterIP Service.
- `gateway.yaml` — `ccm-gateway` + `HTTPRoute` for `https://ccm.${domain}`.
