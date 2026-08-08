
## Deploy

Managed by Flux via `helmrelease.yaml` (chart pulled from the `authentik` `HelmRepository`, https://charts.goauthentik.io).

Sensitive values (`authentik.secret_key`, the Postgres password) are **not** stored in this
repo. They live in Vault at `secret/authentik` and are synced into the `authentik-secret`
Kubernetes Secret by `external-secret.yaml` (via the `vault-secret-store.yaml` SecretStore),
then merged into the Helm values through `helmrelease.yaml`'s `valuesFrom`. See
`setup/vault/kv2.tf` for how those Vault values are populated
(`AUTHENTIK_SECRET_KEY` / `AUTHENTIK_POSTGRESQL_PASSWORD` terraform vars).

To bump the chart/app version, update `spec.chart.spec.version` in `helmrelease.yaml` -
authentik does not support skipping major versions, so upgrade sequentially through each one
in order (see https://docs.goauthentik.io/install-config/upgrade/).

Managed by its own Flux Kustomization (`clusters/production/authentik.yaml`), not the shared
`infrastructure` bundle - same pattern as `node-red`/`kagent`/`cloudflare`.

## Ingress

Traffic comes in via a dedicated Gateway API `Gateway`/`HTTPRoute` in `gateway.yaml`
(nginx-gateway-fabric `GatewayClass`), routed to the chart's `authentik-server` Service -
not the Helm chart's built-in `server.ingress` (left disabled). Same pattern as
`node-red`/`kagent`.

## TLS

Certificates are issued via Let's Encrypt using the shared `components/pki-certman-letsencrypt`
component (DNS-01 through Cloudflare), same as `node-red`/`kagent`. `APP`/`ACME_EMAIL` are
substituted by the dedicated `authentik` Flux Kustomization (`clusters/production/authentik.yaml`).
The component defaults the hostname to `${APP}.${domain}` (`authentik.${domain}`);
`cert-hostname-patch.yaml` overrides it back to the existing `auth.${domain}` to avoid a
public URL change.

`setup/authentik/` holds the Terraform that configures objects inside authentik itself
(OAuth2 providers/applications, users, groups) via the `goauthentik/authentik` provider,
talking to the authentik API directly - separate from this GitOps-managed deployment.
