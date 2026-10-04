
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
| Pocket ID SSO (staging only) | [christiaangoossens/hass-oidc-auth](https://github.com/christiaangoossens/hass-oidc-auth) | `auth_oidc` | Lets people sign in with their Pocket ID account instead of a local Home Assistant password. See [Pocket ID SSO](#pocket-id-sso-staging-only) below — it needs **HA 2025.11+**, so it does not run on staging's current 2022.5.4. |
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
| `auth_oidc.yaml` ConfigMap, mounted at `/config/auth_oidc.yaml` | `apps/common/homeassistant/auth-oidc-config.yaml` |
| egress to `auth.${domain}` | `apps/common/homeassistant/allow-ext-egress-components-netpol.yaml` |

There is no client secret anywhere: the Pocket ID client is a **public client**
using PKCE, which is what the component defaults to and recommends. Nothing is
needed from `setup/vault`.

## Installing

```sh
./pocketid.py --env staging --env-file <env file>   # in setup/pocketid, registers the client
./install-custom-component.sh https://github.com/christiaangoossens/hass-oidc-auth auth_oidc homeassistant
```

`install-custom-component.sh` clones the default branch, so this tracks `main`
rather than a release (v1.2.1 at the time of writing). For something sitting on
the front door, prefer checking out the tag by hand and copying
`custom_components/auth_oidc` from it.

The component declares `aiofiles`, `jinja2` and `joserfc` as requirements, which
Home Assistant pip-installs on first start — `pypi.org`,
`files.pythonhosted.org` and `wheels.home-assistant.io` are already allowed in
the egress policy.

Then, once, on the PVC's `configuration.yaml` (it is not in git):

```yaml
auth_oidc: !include auth_oidc.yaml
```

and restart the deployment. Changes to `auth_oidc.yaml` need a restart too — an
auth provider cannot be reloaded.

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
