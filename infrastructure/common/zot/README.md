# zot

[zot](https://zotregistry.dev) OCI registry, deployed from the upstream helm
chart. Staging only for now ([clusters/staging/zot.yaml](../../../clusters/staging/zot.yaml));
add a production Kustomization with the same substitutions to promote it.

- **URL**: `https://zot.${domain}` (envoy Gateway in `gateway.yaml`, letsencrypt
  cert from `components/pki-certman-letsencrypt`, A record from external-dns).
  The UI and search extensions are enabled, so the same host serves the web UI
  and the registry API.
- **Storage**: 20Gi PVC on `managed-nfs-storage` via the chart's
  volumeClaimTemplate (persistence turns the workload into a StatefulSet).
  Dedupe on, GC daily.
- **Metrics**: the zot metrics extension serves `/metrics` on the registry port;
  the chart's ServiceMonitor is enabled and picked up by monitoring-system.

## No authentication

The registry is deliberately open: anyone who can reach `zot.${domain}` can
pull **and push and delete**. The hostname only resolves to a LAN address, so
this relies on network boundaries. Before putting anything that matters in it,
add htpasswd auth (`secretFiles` in the chart) plus an `accessControl` block in
`config.json`, with the credentials coming from vault through the
secrets-eso-vault component that is already wired up here.

## Vault

The `zot` block in [setup/vault/kv2.tf](../../../setup/vault/kv2.tf) creates
`secret/zot-cf-api-token` (the Cloudflare DNS token for the ACME DNS-01
challenge), the `zot-secrets-role` kubernetes auth role bound to the `zot`
ServiceAccount, and its policy. `terraform apply` there before the first
reconcile or the certificate cannot be issued.

The secrets-eso-vault component also ships an ExternalSecret for `secret/${APP}`,
which zot does not have; `kustomization.yaml` patches it out rather than leave
it permanently in SecretSyncedError (as victoria-metrics does).

## Usage

```
podman push zot.${domain}/myimage:tag      # no login needed
crane catalog zot.${domain}
```
