# kagent

Upgraded from **0.7.0** to **0.10.0** on 2026-09-06.

## Fixed: kagent-ui SIGILL on the Pi 4 (2026-09-06)

Stock `ui:0.10.0`'s `next-server` process crashed with `SIGILL` on real
traffic — confirmed live in production (`kagent.cluster0.cyonomy.net` was
502ing on ~85% of requests). Because the crash happens inside the pod's own
supervisord-managed process (nginx sidecar proxies to `next-server` on
`127.0.0.1:8001`, both in the same container), `kubectl get pods` never
shows it — supervisord silently respawns the crashed process, so it only
shows up in the pod's logs (`terminated by SIGILL (core dumped)`) or as
502s from outside.

**Root cause, confirmed by direct on-demand reproduction:** pulled the
crashed pod's history from Loki and found the real signal — for the pod's
first 42 minutes it received *only* `/health` probe traffic (nginx answers
that itself; it never reaches `next-server`). The instant the first real
browser request landed, `next-server` crashed immediately. It isn't a
duration or warm-up thing — it's the **concurrent burst of many distinct
first-time code paths a real page load fires at once** (a dozen-plus JS
chunks, CSS, a font, the dynamic icon route, all in parallel) hitting V8's
JIT/Wasm compiler for the first time in the process's life. Reproduced
on demand: fresh pod, zero prior traffic, fire `/` plus every real asset
URL from an actual page load simultaneously — stock `ui:0.10.0`
(Node 24.20) crashes on the very first try, every time. There's also no
arm64 native addon anywhere in the standalone build (checked
`find /app/ui/node_modules -iname '*.node'` — only two unreachable x86_64
`sharp` bindings), which rules out the original 0.7.0-pin-era theory of an
`@next/swc` native binary using ARMv8.2-A instructions. This is Node
24.20's V8 emitting something the Cortex-A72 doesn't support, not a
Next.js/Turbopack native binary.

**The fix:** the same `kagent-dev/kagent` `v0.10.0` `ui/` source, rebuilt
with `--build-arg TOOLS_NODE_VERSION=20` instead of the chart's default
`24`, pushed to `docker.io/mthorley/kagent-ui:0.10.0-node20`. Verified with
the identical on-demand repro (fresh pod, same real asset burst, run 4
times) — zero crashes. Then verified again directly against production
with the same burst — zero 502s, zero SIGILL, zero restarts. Build recipe,
Dockerfile reference copy, and rebuild/retirement notes live in
[`setup/kagent/`](../../../setup/kagent/README.md).

An earlier `NODE_OPTIONS=--jitless` stopgap (forcing V8 to interpret-only)
was used to hold production stable while this was built — no longer
needed now that the actual image is fixed, and removed from
`kagent-stack.yaml`.

**Near-miss during this fix, worth remembering:** the `kagent` Flux
Kustomization was suspended (`kubectl patch kustomization kagent --type
merge -p '{"spec":{"suspend":true}}'`) to stop it reverting the live
mitigation back to whatever was last committed — but that suspension was
never surfaced clearly, and something (Flux's own periodic reconcile
picking back up, or a manual resume) un-suspended it mid-fix, which
silently reverted **both** the `--jitless` mitigation and the new image
back to the broken stock image, live, without any explicit action on this
file. If you ever suspend this Kustomization for a live mitigation again:
say so out loud, and get the fix committed+pushed immediately rather than
leaving cluster and git in different states for any longer than
necessary — a suspended Kustomization protecting an uncommitted fix is a
ticking revert, not a stable state.

## Why 0.7.0 was pinned, and why that no longer applies

0.7.0 was the last release before two breaking changes upstream:

- **0.8.x+ requires PostgreSQL.** SQLite support was removed from the
  controller entirely — Postgres is now the only supported backend. This
  chart now deploys the chart's *bundled* Postgres (see below); it was not
  needed at all under 0.7.0.
- **0.8.x+ ships a UI on Next.js 16, and stock `ui:0.10.0` SIGILLs on this
  hardware — see "Fixed: kagent-ui SIGILL" above** (the Deployment now runs
  a custom-built image, not the stock one). A pre-deploy smoke test (a
  handful of sequential requests to `/`, `/agents`, `/models` on
  `ui:0.10.0`) came back clean and this README previously said the issue
  was resolved upstream. That test wasn't rigorous enough: a real page
  load's concurrent asset burst reliably crashes it. Don't trust a few
  sequential curls as proof this is
  fixed in any future version bump either — load-test it properly first.

## Things that changed in this upgrade — read before applying

- **Bundled Postgres, backed by NFS.** The chart's `database.postgres.bundled`
  (a single `postgres:18.6-alpine3.23` pod + PVC, upstream default) is now
  enabled. The only StorageClass in this cluster is `managed-nfs-storage`
  (not marked default), so `bundled.storageClassName` is set explicitly to
  it — otherwise the PVC would sit `Pending` forever. **Postgres data
  directories on NFS are a known risk** (file-locking / fsync semantics);
  upstream's own chart docs say the bundled Postgres is "for development
  and evaluation only, not suitable for production." For a homelab agent
  DB this is probably an acceptable trade-off, but if kagent's data matters,
  point `database.postgres.url` / `urlFile` at a real external Postgres
  instead and set `database.postgres.bundled.enabled=false`.
- **The bundled Postgres password is externalized to Vault, not the chart's
  hardcoded value.** The chart has no values-based override for this (the
  password, secret name, and key are all baked into
  `templates/postgresql-secret.yaml`), so `Secret/kagent-postgresql` is
  stripped from `kagent-stack.yaml` at render time (same `awk` trick
  previously used for the API key) and replaced by
  [postgresql-external-secret.yaml](postgresql-external-secret.yaml), an
  `ExternalSecret` producing a `Secret` with the identical name/key the
  chart's Postgres pod and controller already expect — no chart-side
  changes needed downstream. The value itself lives in Vault at
  `secret/kagent` (key `postgres-password`), added alongside the existing
  Anthropic key in [setup/vault/kv2.tf](../../../setup/vault/kv2.tf) as
  TF var `KAGENT_POSTGRES_PASSWORD`.
  **Before this is applied, someone needs to run `terraform apply` in
  `setup/vault`** with `TF_VAR_KAGENT_POSTGRES_PASSWORD` set (a Terraform
  project outside this GitOps repo's own reconciliation, run by hand against
  the real Vault) — otherwise the ExternalSecret has nothing to pull and the
  Postgres pod won't start.
  Caveat: Postgres only reads `POSTGRES_PASSWORD` on first `initdb`.
  Rotating the value in Vault later updates the k8s Secret but not the
  running database's actual password, and nothing here auto-restarts the
  Postgres pod on rotation (its `checksum/secret` annotation is baked in at
  `helm template` time against the chart's static placeholder, not this
  live Secret).
- **No more SQLite volume.** The `sqlite-volume` `emptyDir` on the
  controller deployment is gone; the controller now talks to
  `kagent-postgresql.kagent:5432`.
- **Existing kagent data does not carry over.** Agents/sessions/history
  living in the 0.7.0 controller's SQLite `emptyDir` are not migrated —
  they were already ephemeral (in-memory `emptyDir`), so there is nothing
  to lose here, but note this for any future non-bundled upgrade too.
- **`querydoc` component is gone.** It was a separate chart dependency in
  0.7.0 (worked around here for a broken arm64 image tag); it's not part of
  the 0.10.0 dependency tree at all, so that workaround is removed.
- **`kmcp.image.tag` override no longer needed.** 0.10.0's `kmcp` subchart
  (now v0.3.0) defaults to `ghcr.io/kagent-dev/kmcp/controller:0.3.0` with no
  `v`-prefix mismatch — confirmed arm64 image exists at that tag.
- **API key wiring is now native to the chart.** 0.7.0 rendered a
  placeholder `Secret` for the Anthropic key and stripped it via `awk`
  post-render, because the chart had no way to point at an existing secret.
  0.10.0 added `providers.anthropic.apiKeySecretRef` /
  `apiKeySecretKey`, so the render now points directly at the existing
  out-of-band `Secret/secret-kagent` (key `anthropic-apikey`, created by the
  `secrets-eso-vault` component) — no placeholder/strip step required.
- Images re-verified as multi-arch (arm64) before rendering:
  `kagent/controller:0.10.0`, `kagent/ui:0.10.0` (live-tested, see above),
  `kagent/tools:0.2.1`, `kmcp/controller:0.3.0`, `postgres:18.6-alpine3.23`.
  `grafana-mcp` still pulls `mcp/grafana:latest` (unpinned) — unchanged from
  0.7.0, not something this upgrade introduced.

## Status

Rendered and committed here for review. **Not yet applied to the cluster.**
Before letting Flux reconcile this, decide on the bundled-Postgres-on-NFS
question above.

To re-render:

```sh
VERSION=0.10.0
helm template kagent-crds oci://ghcr.io/kagent-dev/kagent/helm/kagent-crds \
    --version $VERSION \
    --namespace kagent \
    --create-namespace > kagent-crds-stack.yaml

helm template kagent oci://ghcr.io/kagent-dev/kagent/helm/kagent \
    --version $VERSION \
    --namespace kagent \
    --set providers.default=anthropic \
    --set providers.anthropic.apiKeySecretRef=secret-kagent \
    --set providers.anthropic.apiKeySecretKey=anthropic-apikey \
    --set providers.anthropic.model=claude-sonnet-4-5 \
    --set database.postgres.bundled.storageClassName=managed-nfs-storage \
    --set argo-rollouts-agent.enabled=false \
    --set cilium-debug-agent.enabled=false \
    --set cilium-manager-agent.enabled=false \
    --set cilium-policy-agent.enabled=false \
    --set helm-agent.enabled=false \
    --set istio-agent.enabled=false \
    --set kgateway-agent.enabled=false \
    --set observability-agent.enabled=false \
    --set promql-agent.enabled=false > kagent-stack.yaml

# strip the chart-hardcoded Postgres password secret (externalized via
# postgresql-external-secret.yaml instead -- see note above)
awk 'BEGIN{skip=0} /^# Source: kagent\/templates\/postgresql-secret\.yaml$/{skip=1; next} skip && /^---$/{skip=0; next} !skip{print}' \
    kagent-stack.yaml > kagent-stack.yaml.tmp && mv kagent-stack.yaml.tmp kagent-stack.yaml
```

The API key placeholder-secret strip from 0.7.0 is no longer needed (see
API key note above) — only the Postgres secret needs stripping now.
