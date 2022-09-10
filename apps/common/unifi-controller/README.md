## Install

Derived from

```
helm repo add k8s-at-home https://k8s-at-home.com/charts/
helm repo update
helm template unifi k8s-at-home/unifi -f values.yaml > unifi-stack.yaml
```

and extended by

https://flores.eken.nl/running-unifi-controller-on-k8s/

## Upgrade

### Take Backup
 - Log in to the controller
 - Download the backup, select settings only
e.g. `backup_6.5.55_20220910_1100.unf`

### Install new image
 - Select next version of Unifi Network Application from https://community.ui.com/releases. Ensure the tag is `official` and **not** `release candidate`. Ensure the official version can be migrated to from the existing version.
 - Get the version of the controller image from https://hub.docker.com/r/jacobalberty/unifi/tags
 - Update [values.yaml](./values.yaml) values.yaml with image tag
 - Execute install steps above (e.g. helm generate)
 - Delete `services` fragment from [unifi-stack.yaml](./unifi-stack.yaml)
 - git push to k8s-repo, wait for fluxcd update

### Restore backup
 - Log in to the controller
 - Once on the "wizard" page, restore from backup
