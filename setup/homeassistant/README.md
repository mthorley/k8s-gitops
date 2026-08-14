
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

Tried and removed:

- **airtouch2plus** ([nathanvdh/homeassistant-airtouch2plus](https://github.com/nathanvdh/homeassistant-airtouch2plus)) — controls a Polyaire AirTouch 2+ over local TCP (port 9200), but the unit is on a different house/network than this HA instance with no tunnel between them, so it's unreachable. Revisit once there's a Tailscale/WireGuard link bridging the two LANs.

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
