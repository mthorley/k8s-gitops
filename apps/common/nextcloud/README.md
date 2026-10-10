# nextcloud

Family calendar, contacts and tasks (CalDAV/CardDAV), plus files. Served
LAN-only on `https://nextcloud.${domain}` through envoy-gateway. Enabled on:
**staging**.

| Component | What | State |
| --- | --- | --- |
| `nextcloud` Deployment | `nextcloud:34.0.4-apache` + a `cron` sidecar | `nextcloud-html` (install + `config.php`), `nextcloud-data` (files) |
| `nextcloud-postgres` StatefulSet | `postgres:18.6-alpine` | calendars, contacts, shares, file metadata |
| `nextcloud-valkey` Deployment | `valkey:9.0.6-alpine` | none - file locking + cache only |

## Images

Every image is pulled from the cluster's zot (`zot.${domain}`,
`infrastructure/common/zot`), not Docker Hub, so a restart never depends on
Docker Hub being up or on its pull rate limit. zot has no sync/pull-through
configured, so images are copied in by hand - **arm64 only**, since the Pi 4
nodes are the only consumers and the full multi-arch indexes would cost
several GB of zot's 20Gi:

```sh
Z=zot.${domain}
crane copy --platform linux/arm64 docker.io/nextcloud:34.0.4-apache       $Z/nextcloud:34.0.4-apache
crane copy --platform linux/arm64 docker.io/postgres:18.6-alpine3.23      $Z/postgres:18.6-alpine3.23
crane copy --platform linux/arm64 docker.io/valkey/valkey:9.0.6-alpine3.24 $Z/valkey/valkey:9.0.6-alpine3.24
crane copy --platform linux/arm64 docker.io/alpine:3.23                   $Z/alpine:3.23
```

Bumping a version means copying the new tag in **before** changing the
manifest, or the pod sits in `ImagePullBackOff`.

zot exists on staging only. Promoting Nextcloud to production needs either a
production zot or these references switched back to `docker.io/...`.

## Deployment wiring

`clusters/<env>/nextcloud.yaml` is a dedicated Flux `Kustomization`, for the
same reason as pocket-id: the components need `postBuild.substitute`. It must
supply:

| Substitution | Used by |
| --- | --- |
| `APP: "nextcloud"` | `secret-nextcloud`, Vault paths `secret/nextcloud` + `secret/nextcloud-cf-api-token`, `nextcloud-secrets-role`, the `nextcloud` ServiceAccount, cert `nextcloud-tls-prod` and the hostname |
| `ACME_EMAIL` | the Let's Encrypt `Issuer` |
| `qnap_ip`, `cluster_id` | both backup CronJobs |
| `domain`, `cluster_tz` | from the `cluster-vars` Secret |

DNS comes from `unifi-dns`, which picks up the HTTPRoute hostname by itself.

## Running as www-data on NFS

The image normally starts as root, chowns its volumes to www-data and drops
privileges. `managed-nfs-storage` squashes root, so that chown fails. The pod
therefore runs as uid 33 from the start, which the entrypoint supports: it
skips the chown and runs rsync, `occ` and Apache as 33. Two consequences:

- Apache binds :80 as non-root via the `net.ipv4.ip_unprivileged_port_start`
  pod sysctl.
- The image's `cron.sh` (busybox crond) needs root, so the `cron` sidecar is a
  plain `cron.php` loop every 5 minutes instead.

`kubectl exec` without `--user` would run as root and be squashed to `nobody`,
but the pod's default user is already 33, so plain `occ` works:

```sh
kubectl exec -n nextcloud deploy/nextcloud -c nextcloud -- php occ status
```

## First run

1. Set the `NEXTCLOUD_POSTGRES_PASSWORD`, `NEXTCLOUD_ADMIN_PASSWORD` and
   `NEXTCLOUD_VALKEY_PASSWORD` terraform variables and `terraform apply` in
   the cluster's `setup/vault` workspace **before** Flux applies this - without
   `secret-nextcloud` the pods sit in `CreateContainerConfigError`.
2. Let Flux reconcile. The first start rsyncs the install onto NFS and runs
   `occ maintenance:install`, which takes several minutes on a Pi (the
   startup probe allows 15). Watch with
   `kubectl logs -n nextcloud deploy/nextcloud -c nextcloud -f`.
3. `post-installation.sh` then switches background jobs to cron, sets the AU
   phone region and the maintenance window, and installs Calendar, Contacts
   and Tasks from the app store. App installs are non-fatal; if one failed,
   rerun `php occ app:install <app>`.
4. Log in as `admin` with `NEXTCLOUD_ADMIN_PASSWORD`, then check
   Administration settings > Overview for warnings.

The admin and Postgres passwords are only read on that first start. Changing
them in Vault later does nothing; change them in Nextcloud / with
`ALTER ROLE`. The installer also creates its own `oc_admin` DB role that
Nextcloud actually connects as - its password is in `config.php`.

## Calendar clients

| Client | Setup |
| --- | --- |
| iPhone / Mac | Settings > Calendar > Accounts > Add Account > Other > CalDAV, server `nextcloud.${domain}` |
| Android | DAVx5, base URL `https://nextcloud.${domain}` |
| Bots / scripts | `https://nextcloud.${domain}/remote.php/dav` with an app password (Personal settings > Security) |

`/.well-known/caldav` and `/.well-known/carddav` are answered by Nextcloud's
`.htaccess` with a redirect to `/remote.php/dav`; `OVERWRITEPROTOCOL=https`
keeps that redirect on https behind the gateway.

Give each person their own account and share a "Family" calendar with all of
them - Nextcloud does real calendar sharing, unlike Radicale.

## Not done yet

- **Access from outside the house.** LAN-only for now. Phones need either a
  VPN or a Cloudflare tunnel route without Access (CalDAV clients cannot do the
  Access login).
- **Pocket ID SSO** via the `user_oidc` app. Only the web login benefits;
  CalDAV clients keep using per-device app passwords.
- **Egress lockdown.** Nextcloud talks to the app store, update checker and
  push proxy, so there is no default-deny egress yet; `netpol/` only limits
  who can reach Postgres and Valkey.
- **Production.**

## Upgrades

Pinned to an exact release, copied into zot first (see Images). Nextcloud can only upgrade **one major at a
time** (34 -> 35, never 34 -> 36), so bump deliberately. On start the
entrypoint notices the newer image, rsyncs it over `/var/www/html` and runs
`occ upgrade`. Take a fresh `pg_dump` first.

## Backups

- `nextcloud-postgres-backup` - nightly 01:15 `pg_dump` to
  `<qnap>:/k8s/backup/${cluster_id}/nextcloud-db`, keeping 14.
- `nextcloud-data-backup` - nightly 01:45 tarball of `nextcloud-data` to
  `.../nextcloud-data`, keeping 10, minus the preview cache. Its own job
  rather than `components/backup-cron-nfs`, which runs as root - squashed to
  `nobody` on NFS and so locked out of the 0770 data directory. Running as
  uid 33 instead means the QNAP backup share must be writable by uid 33.

`nextcloud-html` is not backed up. Everything in it can be recreated except
`config/config.php` (instance id, secret, DB password) - copy that out after
the first run.

`managed-nfs-storage` reclaims with **Delete**: removing a PVC (or the
namespace) deletes its data.
