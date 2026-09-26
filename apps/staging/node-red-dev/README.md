# node-red-dev

Staging Node-RED, deployed by `clusters/staging/nodereddev.yaml` with
`APP: "nodereddev"`. Served on `https://nodereddev.${domain}` via the `nginx`
GatewayClass (`ingress.yaml`).

## Editor login (Pocket ID OIDC)

The editor is protected by `adminAuth` in `settings.js`, using
`passport-openidconnect` against Pocket ID (`apps/common/pocket-id`) on
`https://auth.${domain}`. This replaced the previous Authentik configuration;
Node-RED supports exactly one `adminAuth` strategy, so it is the only way in.

### How settings.js reaches the pod

`settings.js` is version controlled here and rendered into a ConfigMap by the
`configMapGenerator` in `kustomization.yaml`, then mounted over `/data/settings.js`
with `subPath` — `/data` itself stays on the PVC, so flows, credentials and
installed nodes are untouched.

Two things make this work:

- The generated ConfigMap name carries a **content hash**, so editing
  `settings.js` changes the pod spec and rolls Node-RED. Without the hash the
  ConfigMap would update silently and the running editor would keep serving the
  old login config.
- `${domain}` inside `settings.js` is **not** a JS template literal. Flux
  `postBuild` substitutes it from the `cluster-vars` Secret when the ConfigMap is
  rendered. Never introduce a real backtick template literal into that file —
  Flux would substitute it too and blank it out.

The mount is read-only, which is safe: Node-RED reads `settings.js` and writes
its mutable state to `.config.*.json` alongside it.

> Before the first reconcile of this change, diff the `settings.js` here against
> the copy currently on the PVC. Until now the file lived only on the volume, so
> anything changed there by hand and never mirrored back into git will be
> overwritten by the mount.

### Client registration

Pocket ID has no terraform provider, so the client is created by hand:

1. In the Pocket ID admin UI, add an OIDC client with callback
   `https://nodereddev.${domain}/auth/strategy/callback`.
2. Put the resulting id/secret into the `POCKETID_NODERED_CLIENTID` /
   `POCKETID_NODERED_SECRET` terraform variables and apply `setup/vault` — they
   land in Vault at `secret/nodereddev` as `oidc-client-id` / `oidc-client-secret`.
3. The `secrets-eso-vault` component syncs those into `secret-nodereddev`, which
   the Deployment exposes as `CLIENT_ID` / `CLIENT_SECRET`.

### Authorising a user

`adminAuth.users` matches on `profile.username`, which `passport-openidconnect`
reads from Pocket ID's `preferred_username` claim — so entries are Pocket ID
usernames, **not** email addresses. Authenticating successfully but being absent
from that list gets you no access, which is the usual cause of a login that
loops back to the sign-in button.

### Image dependency

`passport-openidconnect` must be present in the `mthorley/node-red` image — it is
`require`d at the top level of `settings.js`, so if it is missing Node-RED will
not start at all. It was already required by the previous Authentik config, so
the current image has it; keep that in mind when rebuilding the image.

## Projects

Git integration for Node-RED projects is enabled via:

```
- name: NODE_RED_ENABLE_PROJECTS
  value: "true"
```
