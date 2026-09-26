
Enable git integration for projects
```
- name: NODE_RED_ENABLE_PROJECTS
  value: "true"
```
## Editor login (Pocket ID OIDC)

The editor is protected by `adminAuth` in `settings.js`, using
`passport-openidconnect` against the cluster's own Pocket ID
(`apps/common/pocket-id`) on `https://auth.${domain}`. This directory is deployed
by both clusters (staging directly, production via `apps/production/node-red`),
so each cluster's node-red logs in against its own Pocket ID with its own client.

`settings.js` is the same file as `apps/staging/node-red-dev/settings.js` apart
from the callback host and log level - see that README for how the ConfigMap
mount, the content hash and the `${domain}` Flux substitution work, how users are
authorised, and why logout redirects to Pocket ID's end-session endpoint.

### Client registration

Done once per cluster, in that cluster's Pocket ID admin UI:

1. Add an OIDC client with callback `https://nodered.${domain}/auth/strategy/callback`.
2. Put the id/secret into `POCKETID_NODERED_CLIENTID_PROD` / `_SECRET_PROD`
   (production) or `POCKETID_NODERED_CLIENTID_STG` / `_SECRET_STG` (staging) and
   apply `setup/vault` in the matching workspace. `var.ENV` picks the pair; they
   land in Vault at `secret/nodered` as `oidc-client-id` / `oidc-client-secret`.
3. The `secrets-eso-vault` component syncs those into `secret-nodered`, which the
   Deployment exposes as `CLIENT_ID` / `CLIENT_SECRET`.

**Do this before the settings.js change reaches a cluster.** With an empty
`CLIENT_ID`, `passport-openidconnect` throws at startup and Node-RED
crash-loops - flows stop running, not just the editor.

### Egress

No extra network policy is needed: `netpol/allow-ext-egress-netpol.yaml` already
allows `192.168.0.0/16`, which covers each cluster's Pocket ID LoadBalancer IP.
