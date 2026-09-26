
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

### How settings.js reaches the pod

`settings.js` is version controlled here and rendered into a ConfigMap by the
`configMapGenerator` in `kustomization.yaml`, then mounted over `/data/settings.js`
with `subPath` - `/data` itself stays on the PVC, so flows, credentials and
installed nodes are untouched. The mount is read-only, which is safe: Node-RED
reads `settings.js` and writes its mutable state to `.config.*.json` beside it.

- The generated ConfigMap name carries a **content hash**, so editing
  `settings.js` changes the pod spec and rolls Node-RED. Without it the
  ConfigMap would update silently and the running editor would keep the old
  login config.
- `${domain}` inside `settings.js` is **not** a JS template literal. Flux
  `postBuild` substitutes it from the `cluster-vars` Secret when the ConfigMap is
  rendered. Never introduce a real backtick template literal into that file -
  Flux would substitute it too and blank it out.

### Authorising a user

`adminAuth.users` matches on `profile.username`, which `passport-openidconnect`
reads from Pocket ID's `preferred_username` claim - so entries are Pocket ID
usernames, **not** email addresses. Authenticating successfully but being absent
from that list gets you no access, which is the usual cause of a login that
loops back to the sign-in button.

### Logout

The editor's logout only revokes Node-RED's own token. The Pocket ID session
outlives it, so without more config the next request silently signs straight
back in and logout appears to do nothing. `editorTheme.logout.redirect` sends the
browser on to Pocket ID's `https://auth.${domain}/api/oidc/end-session` to end
that session as well.

### Image dependency

`passport-openidconnect` must be present in the node-red image - it is
`require`d at the top level of `settings.js`, so if it is missing Node-RED will
not start at all.

### Client registration

Both clusters' node-red use one shared Pocket ID client - same id and secret - registered in each cluster's Pocket ID by
`setup/pocketid/pocketid.py` from `setup/pocketid/config.yaml`:

1. Set `POCKETID_NODERED_CLIENTID` / `POCKETID_NODERED_SECRET` (secret: 16+
   printable ASCII characters).
2. Run `setup/pocketid/pocketid.py --env <staging|prod>` to register the client
   with that id and secret.
3. Apply `setup/vault` in the same workspace - the same pair lands in Vault at
   `secret/nodered` as `oidc-client-id` /
   `oidc-client-secret`.
4. The `secrets-eso-vault` component syncs those into `secret-nodered`, which the
   Deployment exposes as `CLIENT_ID` / `CLIENT_SECRET`.

**Do this before the settings.js change reaches a cluster.** With an empty
`CLIENT_ID`, `passport-openidconnect` throws at startup and Node-RED
crash-loops - flows stop running, not just the editor.

### Egress

No extra network policy is needed: `netpol/allow-ext-egress-netpol.yaml` already
allows `192.168.0.0/16`, which covers each cluster's Pocket ID LoadBalancer IP.
