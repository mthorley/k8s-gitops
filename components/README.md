# Components to ensure DRY

## Structure

All components take the structure ```<function>-<framework>-<backend>```, examples include

```
secrets-eso-vault
pki-certman-vault
pki-certman-letsencrypt
backup-volsync-nfs
```
## secrets-eso-vault

Provides vault secrets via External Secrets Operator as k8s secrets.

### Vars

| Vars | Description | Example |
| -------- | ----------- | ------- |
| APP | Name of the application | nodered |

## pki-certman-vault

Provides certificate mangement using cert-manager and vault pki.

### Vars

| Vars | Description | Example |
| -------- | ----------- | ------- |
| APP | Name of the application | nodered |

## pki-certman-letsencrypt

Provides certificate mangement using cert-manager and Letencrypt for ingress.

### Vars

| Vars | Description | Example |
| -------- | ----------- | ------- |
| APP | Name of the application | nodered |
| ACME_EMAIL | email used for notification on cert expiry | email |

## backup-cron-nfs

Nightly tar backup of a PVC to an NFS share via a CronJob, keeping the last 10 archives.

### Vars

| Vars | Description | Example |
| -------- | ----------- | ------- |
| APP | Name of the application | nodered |
| BACKUP_SOURCE_CLAIM | PVC claim name to back up | node-red-claim |
| BACKUP_SCHEDULE | Cron schedule for the backup | 0 0 * * * |
| qnap_ip | NFS server IP (already defined per-cluster) | 192.168.1.147 |
| cluster_id | Cluster identifier (already defined per-cluster) | cluster0 |
| cluster_tz | Timezone the schedule is evaluated in (already defined per-cluster); without this the schedule runs in UTC | Australia/Melbourne |

# Example

```
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
namespace: node-red
generatorOptions:
  disableNameSuffixHash: true
resources:
  - namespace.yaml
  - pvc.yaml
  - serviceaccount.yaml
  - deployment.yaml
  - service.yaml
  - ingress.yaml

components:
  - ../../../components/secrets-eso-vault
  - ../../../components/pki-certman-letsencrypt

```
