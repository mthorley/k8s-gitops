
# Gluetun VPN with torrent client Deluge

Uses Gluetun as VPN client sidecar to Deluge torrent client.

# Gotchas

## Ingress nor LoadBalancer doesn't forward to Deluge UI port

Ensure firewall input ports are specified for a [sidecar configuration](https://github.com/qdm12/gluetun-wiki/blob/main/setup/options/firewall.md):

```
  containers:
    - name: gluetun
      env:
        - name: FIREWALL_INPUT_PORTS
          value: "8112"                 # deluge UI
```

## Setup homeassistant to manage Deluge

The following configuration is required to enable ha to be able to control Deluge:

<future>
