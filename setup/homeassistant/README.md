
# Installing a custom component (non-HACS)

`/config` is served from the `home-assistant-config` PVC, not tracked in git,
so custom components are installed directly onto the running pod:

```
./install-custom-component.sh <git-repo-url> [component-name] [namespace]

# e.g.
./install-custom-component.sh https://github.com/bigmoby/fglair_for_homeassistant
```

This clones the repo, copies its `custom_components/<name>/` folder into the
pod's `/config/custom_components/`, and restarts the deployment. Then finish
setup in the UI: Settings -> Devices & Services -> Add Integration.

Re-run this after the `home-assistant-config` PVC is recreated (it's not
backed by git, so anything below is lost with the volume).

## Currently installed

| Component | Repo | Domain | Notes |
|---|---|---|---|
| FGLair heat pump controller | [bigmoby/fglair_for_homeassistant](https://github.com/bigmoby/fglair_for_homeassistant) | `fglair_heatpump_controller` | Controls a Fujitsu AC over the FGLair/Ayla cloud API. Installed to work around the official `fujitsu_fglair` core integration refusing `AC-UTY`-prefixed devices ([home-assistant/core#132460](https://github.com/home-assistant/core/issues/132460), closed not-planned) — this fork's `pyfujitsugeneral` dependency has no such prefix check. |
| Airtouch2Plus | self-authored, vendored at [`airtouch2plus/`](airtouch2plus/) (no upstream repo) | `airtouch2plus` | Controls a Polyaire AirTouch 2+ over Polyaire's cloud relay (`app2plus.airtouch.com.au:9200`, same protocol as the official app), not local TCP — sidesteps the earlier local-network unreachability problem (see below). `iot_class: cloud_polling`. Requires `app2plus.airtouch.com.au` in `allow-ext-egress-components-netpol.yaml`. Installed via `install-custom-component.sh`'s copy step, sourced from the local `airtouch2plus/` folder instead of a git clone since there's no upstream repo. AC/zone control commands are unverified against a real device — see [`airtouch2plus/README.md`](airtouch2plus/README.md). |
| Pocket ID SSO (staging only) | [christiaangoossens/hass-oidc-auth](https://github.com/christiaangoossens/hass-oidc-auth) | `auth_oidc` | Lets people sign in with their Pocket ID account instead of a local Home Assistant password. See [Pocket ID SSO](#pocket-id-sso-staging-only) below. Needs **HA 2025.11+**, which is why staging was moved to 2026.8.3. Must be installed from the release zip, not a git clone. |
| Zen WiFi Thermostat | self-authored, vendored at [`zenwifi/`](zenwifi/), ported from [mthorley/zen-wifi-client](https://github.com/mthorley/zen-wifi-client) (Node.js, not directly usable in HA) | `zenwifi` | Controls a Zen Ecosystems WiFi thermostat over its cloud API (`wifi.zenhq.com`), same as the official app. `iot_class: cloud_polling`. Requires `wifi.zenhq.com` in `allow-ext-egress-components-netpol.yaml`. Installed via `install-custom-component.sh`'s copy step, sourced from the local `zenwifi/` folder instead of a git clone since the upstream repo isn't a HA custom component. Mode/setpoint write commands are unverified against a real device — see [`zenwifi/README.md`](zenwifi/README.md). |

Tried and removed:

- **pocketid_auth (self-authored)** — a from-scratch OIDC auth provider for Pocket ID. Dropped in favour of the upstream `hass-oidc-auth` above, which does the same job and more (device-code login for the companion apps, a welcome screen, an auto-redirecting login page) and is maintained.
- **airtouch2plus (nathanvdh fork)** ([nathanvdh/homeassistant-airtouch2plus](https://github.com/nathanvdh/homeassistant-airtouch2plus)) — controls a Polyaire AirTouch 2+ over local TCP (port 9200), but the unit is on a different house/network than this HA instance with no tunnel between them, so it's unreachable. Superseded by the self-authored cloud-relay version above.

# Pocket ID SSO (staging only)

[`hass-oidc-auth`](https://github.com/christiaangoossens/hass-oidc-auth) adds a
Pocket ID login alongside the normal Home Assistant one. Everything except the
component itself is GitOps, and only `apps/staging` builds
`apps/common/homeassistant` — production's reference to it is commented out and
production runs `apps/production/ha-dev`, which is untouched by this.

> [!IMPORTANT]
> The component needs **Home Assistant 2025.11 or newer** (`hacs.json`), so
> staging was moved from **2022.5.4** to **2026.8.3** (the tag
> `apps/production/ha-dev` already runs) in the same change. The recorder
> schema migration on first start is one-way — going back to 2022.5.4 means
> restoring the `home-assistant-config` PVC from backup. Expect breaking
> changes across that gap: check the staging instance's YAML config and
> integrations before relying on it.

| piece | where |
| --- | --- |
| Pocket ID groups + public OIDC client | [`setup/pocketid/config.yaml`](../pocketid/config.yaml) |
| whole `configuration.yaml` — `http:` (trusted proxies) and `auth_oidc:` inline — mounted over the PVC copy | `apps/common/homeassistant/configuration.yaml` (configMapGenerator) |
| TLS hostname `homeassistant.${domain}` | `apps/common/homeassistant/gateway.yaml` |
| own Flux Kustomization carrying `APP=homeassistant` | [`clusters/staging/homeassistant.yaml`](../../clusters/staging/homeassistant.yaml) |
| Cloudflare DNS token for the ACME challenge | [`setup/vault/homeassistant-kv2.tf`](../vault/homeassistant-kv2.tf) |
| egress to `auth.${domain}` | `apps/common/homeassistant/allow-ext-egress-components-netpol.yaml` |

There is no client secret anywhere: the Pocket ID client is a **public client**
using PKCE, which is what the component defaults to and recommends. The only
thing `setup/vault` holds is the Cloudflare DNS token for the certificate.

### Why Home Assistant is behind the gateway

Pocket ID refuses plain-http callback URLs —
`ALLOW_INSECURE_CALLBACK_URLS: "false"` in
[`apps/common/pocket-id/deployment.yaml`](../../apps/common/pocket-id/deployment.yaml),
deliberately, because an http callback silently downgrades a login. An attempt
to use `http://<lan-ip>:8123/auth/oidc/callback` is rejected at the authorize
step with:

```
error=invalid_request … Redirect URL is using an insecure protocol,
http is only allowed for hosts with suffix 'localhost'
```

So Home Assistant is served over TLS on `homeassistant.${domain}` like every
other OIDC client here. Two consequences:

- **Start the login at `https://homeassistant.${domain}/`**, not at the
  LoadBalancer IP. `${homeassistant_ip}:8123` still works for everything else;
  SSO is the exception, because the component derives its redirect URI from the
  incoming request.
- Home Assistant moved out of the `apps/staging` bundle into its own Flux
  Kustomization, because the cert and SecretStore components are keyed on
  `${APP}` and the bundle sets no `APP`. Same split as node-red, zot and
  pocketid. Production is untouched — it runs `apps/production/ha-dev`, and
  `apps/production/kustomization.yaml` keeps `../common/homeassistant`
  commented out.

The hostname is `homeassistant.${domain}` rather than something shorter because
`components/pki-certman-letsencrypt` issues for `${APP}.${domain}`; a shorter
name would need a cert-hostname patch like pocket-id has.

## Installing

> [!IMPORTANT]
> **Install from the release zip, never from a git clone.** This component sets
> `"zip_release": true` in `hacs.json`: `static/style.css` is compiled from
> `static/input.css` by its release workflow and **is not in the git tree**. A
> cloned install loads fine, completes OIDC discovery, and then returns **HTTP
> 500 on the welcome page** with `ValueError: Static file
> '…/static/style.css' not found`. Learned the hard way, 2026-10-04.

```sh
# 1. Register the groups and the OIDC client in Pocket ID (from setup/pocketid)
./pocketid.py --env staging --env-file <env file> --dry-run
./pocketid.py --env staging --env-file <env file>

# 2. Install the component from the pinned release zip
./install-custom-component.sh \
  https://github.com/christiaangoossens/hass-oidc-auth/releases/download/v1.2.1/hass-oidc-auth.zip \
  auth_oidc homeassistant
```

`install-custom-component.sh` takes a release-zip URL as well as a git URL. The
zip's root *is* the component (no `custom_components/` prefix), which is the
HACS `zip_release` convention, so the component name has to be passed
explicitly — nothing in the archive names it.

Using the zip also pins the install to a release rather than tracking `main`,
which is what you want for something on the front door.

The component declares `aiofiles`, `jinja2` and `joserfc` as requirements, which
Home Assistant pip-installs on first start — `pypi.org`,
`files.pythonhosted.org` and `wheels.home-assistant.io` are already allowed in
the egress policy.

Nothing to edit on the PVC afterwards: `configuration.yaml` itself is a
ConfigMap generated from `apps/common/homeassistant/configuration.yaml`, mounted read-only over the copy onboarding
writes, with the `http:` and `auth_oidc:` blocks inline. It survives the volume
being recreated. Change it in git and push — Home Assistant restarts on the new
pod spec, and an auth provider cannot be reloaded without a restart anyway.

Until the component is installed, Home Assistant logs a setup failure for the
unknown `auth_oidc` integration and otherwise runs normally.

Before the first login, `terraform apply` in [`setup/vault`](../vault) so
`secret/homeassistant-cf-api-token` exists — cert-manager cannot complete the
DNS-01 challenge without it, and the gateway has no certificate until it does.

## Notes

- `automatic_user_linking` is on, so the first Pocket ID sign-in adopts the
  existing Home Assistant account with the same username rather than making an
  empty new one. Turn it off in the ConfigMap once everyone has signed in once:
  while it is on, any Pocket ID user whose username matches a Home Assistant
  user gets that account, bypassing any MFA on it.
- `roles.admin` only applies when the Home Assistant user is **created**.
  Adding someone to `homeassistant-admins` later does not promote an existing
  account — change it in Settings → People.
- Keep one working local password account. If Pocket ID is down the normal
  login is the way back in; append `?skip_oidc_redirect=true` to reach it.
- The Pocket ID client's callback URL is the literal staging LAN address
  (`http://192.168.3.19:8123/auth/oidc/callback`), because Home Assistant is on
  a LoadBalancer IP rather than behind the envoy gateway. Moving it behind the
  gateway means changing the callback in Pocket ID and the discovery/redirect
  side together.

# Configuration for unifi controller

## UDMProMax
```
host:       unifi
username:   <username>
password:   <pwd>
port:       8443
verify SSL: unchecked
```

## Network application running in cluster

Via unifi home assistant component UI:

```
host:       unifi-tcp.unifi-controller
username:   <username>
password:   <pwd>
port:       8443
verify SSL: unchecked
```

## Add qbittorrent Integration

```
Host: torrent-internal.torrent.svc.cluster.local
Port: 80
SSL:  off (it's plain HTTP internally; TLS termination only happens at the external gateway)
```
