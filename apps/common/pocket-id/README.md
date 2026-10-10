# pocket-id

OIDC provider for the cluster, replacing authentik (removed — see "Migration
from authentik" below). Pocket ID is passkey-first: there are no passwords, so
every login is a WebAuthn assertion against a registered authenticator.

Served on `https://auth.${domain}` — the hostname authentik used, deliberately
reused so it stays memorable. A single Go binary with SQLite, no Postgres and no
Redis, which is the main reason it is a better fit here than authentik was.

## Deployment wiring

Both clusters deploy it from here: `clusters/staging/pocketid.yaml` and
`clusters/production/pocketid.yaml` are identical, and everything cluster-specific
comes from `cluster-vars` - so staging serves `auth.cluster1.cyonomy.net` and
production `auth.cluster0.cyonomy.net`. They are two independent IdPs: separate
SQLite databases, users, passkeys and OIDC clients. A client registered on one
does not exist on the other.

Both clusters' Vaults are populated from the same `setup/vault` terraform, one
workspace each (`staging`, `prod`), so the `pocketid` Vault role, policy and
secrets exist on production only after `terraform apply` in the `prod`
workspace.

It **cannot** go in the bundled `apps/staging/kustomization.yaml` alongside
`pi-temp-agent`/`mqtt`, because both components below depend on Flux
`postBuild.substitute` for `${APP}`, which plain kustomize leaves as a literal.
Hence the dedicated Flux `Kustomization`, same as `node-red`/`ccm`/`torrent`.

Each `clusters/<env>/pocketid.yaml` must supply:

| Substitution | Used by |
| --- | --- |
| `APP: "pocketid"` | both components — `secret-pocketid`, Vault path `secret/pocketid`, `pocketid-secrets-role`, the `pocketid` ServiceAccount, cert name `pocketid-tls-prod` |
| `ACME_EMAIL` | the Let's Encrypt `Issuer` |
| `domain`, `cluster_tz` | from the `cluster-vars` Secret |

### Why APP is "pocketid" but the host is "auth"

`components/pki-certman-letsencrypt` hardcodes the certificate's `dnsNames` to
`${APP}.${domain}`. `APP` also drives the Vault path, the secrets role and the
ServiceAccount name, where `auth` would be uninformatively generic. So `APP`
stays `pocketid` and `cert-hostname-patch.yaml` overrides the `dnsNames` back to
`auth.${domain}` — the same trick the old `infrastructure/common/authentik`
used, for the same reason.

The `pocketid` ServiceAccount name is load-bearing: `components/secrets-eso-vault`
binds the Vault Kubernetes auth role to a ServiceAccount named `${APP}` and
annotates a token Secret of the same name onto it.

## State

Everything that makes the issuer identity stable lives on `pocket-id-claim`:
the SQLite database, the generated OIDC signing keys, and uploaded avatars.

**Losing that volume invalidates every registered passkey and every OIDC client
secret.** There is no recovery path other than re-registering authenticators, so
it is worth including in whatever backs up `managed-nfs-storage`.

`ReadWriteOnce`, unlike most claims in this repo, and the Deployment uses
`strategy: Recreate`: SQLite tolerates exactly one writer, so the old pod has to
be gone before the replacement starts. Do not scale `replicas` above 1.

## Postgres (component)

SQLite on `managed-nfs-storage` crashed Pocket ID: SQLite runs in WAL mode,
whose shared-memory locking does not work over NFS, so writes from Pocket ID's
own hourly jobs (the `:35` SCIM sync, the `:56` cleanup cron) blocked on locks
for 30s+, the actor-host health check timed out and the process exited.

`postgres/` is a kustomize Component that adds a single-replica
`postgres:18.6-alpine` StatefulSet (same image/uid as kagent's, which already
runs on this NFS), points `DB_CONNECTION_STRING` at it, and adds a nightly
`pg_dump` to `<qnap>:/k8s/backup/${cluster_id}/pocketid`. A cluster opts in with
`components: [postgres]` in `clusters/<env>/pocketid.yaml`, which also has to
substitute `qnap_ip` and `cluster_id`. Enabled on: **staging**.

`pocket-id-claim` stays - it still holds uploads.

### Migrating a cluster from SQLite

1. Set the `POCKETID_POSTGRES_PASSWORD` terraform variable (`openssl rand -hex 24`)
   and `terraform apply` in that cluster's `setup/vault` workspace, then check
   `secret-pocketid` has `postgres-password` and `db-connection-string`
   (ExternalSecret refresh is 10m). Doing this first matters: without those keys
   the pods sit in `CreateContainerConfigError`.
2. Export from the still-running SQLite instance onto the volume. `kubectl exec`
   runs as root, which NFS squashes to `nobody` and locks out of the
   `drwx------` uploads dir - so drop to the server's uid with `su-exec`, as the
   image's entrypoint does:
   `kubectl exec -n pocket-id deploy/pocket-id -- su-exec 1000:1000 /app/pocket-id export -p /app/data/sqlite-export.zip`
3. Add `components: [postgres]` (plus `qnap_ip`/`cluster_id`) to
   `clusters/<env>/pocketid.yaml` and let Flux apply it. Pocket ID starts on an
   empty Postgres and creates its tables.
4. Import, then restart:
   `kubectl exec -n pocket-id deploy/pocket-id -- su-exec 1000:1000 /app/pocket-id import -p /app/data/sqlite-export.zip --forcefully-acquire-lock -y`
   `kubectl rollout restart -n pocket-id deploy/pocket-id`
5. Log in with an existing passkey and through an OIDC client (Node-RED) to
   confirm users, passkeys, clients and signing keys came across. Then remove
   `sqlite-export.zip` and the old `pocket-id.db*` files from the volume.

Rollback before step 5: drop the component line; the SQLite files are untouched.

## Secrets

`ENCRYPTION_KEY` (encrypts TOTP secrets and API keys at rest) comes from Vault
at `secret/pocketid`, synced to the `secret-pocketid` Secret by the
`secrets-eso-vault` component. It is populated by the `POCKETID_ENCRYPTION_KEY`
terraform variable in `setup/vault/kv2.tf`.

Rotating that key makes existing ciphertext unreadable — it is generated once
(`openssl rand -base64 32`) and left alone.

## First run

1. Let Flux reconcile, then confirm the certificate is issued and
   `auth.${domain}` resolves (split-horizon DNS comes from `unifi-dns`).
2. Visit `https://auth.${domain}/setup` to create the admin account. This
   endpoint stops working once an admin exists, so do it promptly.
3. Register a passkey. Register a second authenticator as backup — a lost sole
   passkey means falling back to a one-time access link generated from the CLI
   inside the pod.

## OIDC clients

Groups, users and OIDC clients are declared in `setup/pocketid/config.yaml` and
applied to each cluster's instance through the admin API by
`setup/pocketid/pocketid.py` - see that README. Client ids and secrets come from
the same variables `setup/vault` writes into the consuming app's Vault secret, so
both sides always hold the same value. Current clients:

| Client | Callback | Credentials land in |
| --- | --- | --- |
| Node-RED editor | `https://nodered.${domain}/auth/strategy/callback` | `secret/nodered` as `oidc-client-id` / `oidc-client-secret` |

Grafana SSO is wired up in `setup/vault/grafana-ini-oauth.tftpl` but **not
currently enabled** — `setup/vault/grafana-kv2.tf` renders
`grafana-ini-unauth.tftpl` instead. Enabling it needs a Grafana client here plus
a switch of that `templatefile()` call.

### Endpoints

Pocket ID's paths are not the conventional OIDC ones, which matters for any
client that cannot consume discovery:

| | |
| --- | --- |
| Issuer | `https://auth.${domain}` |
| Discovery | `https://auth.${domain}/.well-known/openid-configuration` |
| Authorization | `https://auth.${domain}/authorize` |
| Token | `https://auth.${domain}/api/oidc/token` |
| UserInfo | `https://auth.${domain}/api/oidc/userinfo` |
| JWKS | `https://auth.${domain}/.well-known/jwks.json` |
| End session | `https://auth.${domain}/api/oidc/end-session` |

Note `/authorize` has no prefix while the back-channel calls sit under
`/api/oidc` — an easy thing to get wrong by analogy with other providers.

## Ingress

A dedicated Gateway API `Gateway`/`HTTPRoute` in `gateway.yaml` on the `envoy`
`GatewayClass`, routed to the `pocketid-internal` Service — same pattern as
`node-red`/`ccm`.

Unlike those, the Gateway points at an `EnvoyProxy` (`envoyproxy.yaml`) that
sets its LoadBalancer Service to `externalTrafficPolicy: Cluster`. Pocket ID has
in-cluster clients (node-red's back-channel token call goes to
`auth.${domain}`, i.e. the LB IP), and with Envoy's default `Local` kube-proxy -
which runs without a `clusterCIDR` here - rejects pod traffic with
`EHOSTUNREACH` unless the caller shares a node with the envoy pod. The cost is
that Pocket ID sees a node IP rather than the real client IP in its sign-in
logs.

`TRUST_PROXY=true` is required: TLS terminates at the gateway, so without it
Pocket ID sees the gateway's pod IP as the client and builds `http://` callback
URLs, which then fail client validation.

## Upgrades

The image is pinned to an exact release (`v2.16.0`) rather than the floating
`:v2` tag, so an upstream push cannot restart the IdP unprompted. Bump it
deliberately and read the release notes — Pocket ID is pre-1.0-ish in its
willingness to change defaults between minors.

Unlike authentik, it is not mirrored into the per-cluster `zot`
(`infrastructure/common/zot`); it pulls from ghcr.io. Worth mirroring if pod
restarts during a ghcr.io outage ever become a problem, as was done for
`node-red`.

## Migration from authentik

authentik was never actually deployed — `../common/authentik` was commented out
of `infrastructure/staging/kustomization.yaml` and absent from production, and
its Grafana OAuth template was commented out too. Removing it therefore changed
nothing running. Gone in the same change as this directory:

- `infrastructure/common/authentik/`, `infrastructure/staging/cert-issuer-authentik.yaml`
- `setup/authentik/` (the terraform that configured objects inside authentik via
  its API — Pocket ID has no equivalent provider). Local `terraform.tfstate*`
  files were deliberately left on disk, untracked.
- `setup/vault`: the `authentik` policy/role/kv secrets, the
  `auth-issuer-cert-role` PKI role bound to the now-absent `authentik`
  namespace, and the `AUTHENTIK_*` variables (renamed `POCKETID_*`).

`terraform apply` in `setup/vault` will therefore **destroy** the `authentik`
Vault objects listed above. That is intended, but check the plan.
