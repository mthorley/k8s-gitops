
# Gluetun VPN with torrent client qBittorrent

Uses Gluetun as VPN client sidecar to the qBittorrent torrent client.

Migrated from Deluge because qBittorrent is a single process (no
separate daemon/webUI to fall out of sync after a pod restart) and has a
native Home Assistant integration, which Deluge lacks.

# Gotchas

## Ingress nor LoadBalancer doesn't forward to the qBittorrent UI port

Containers in the pod share a network namespace with gluetun, so gluetun's
firewall applies to Service->Pod traffic too. Ensure firewall input ports
are specified for a [sidecar configuration](https://github.com/qdm12/gluetun-wiki/blob/main/setup/options/firewall.md):

```
  containers:
    - name: gluetun
      env:
        - name: FIREWALL_INPUT_PORTS
          value: "8080"                 # qBittorrent WebUI
```

## First login

The linuxserver/qbittorrent image generates a random temporary WebUI
password on first start and prints it to the container logs (there's no
`WEBUI_PASSWORD` env var on this image). Grab it with:

```
kubectl -n torrent logs deploy/qbittorrent -c qbittorrent | grep -i password
```

Log in as `admin` with that password and change it immediately under
Settings > WebUI.

## Home Assistant

qBittorrent has a built-in HA integration (Settings > Devices & Services >
Add Integration > qBittorrent) — point it at the ingress URL and the
credentials set above. No custom/HACS component needed, unlike Deluge.

## No port forwarding

ExpressVPN (the current `VPN_SERVICE_PROVIDER`) does not support VPN port
forwarding at all, so Gluetun's automatic port-forward-to-client wiring
isn't usable here regardless of torrent client. In practice this mostly
affects seed ratio on private trackers and connectability on small/rare
swarms — public-tracker downloading is largely unaffected.
