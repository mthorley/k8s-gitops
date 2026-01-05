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

# Example

```
apiVersion: kustomize.config.k8s.io/v1
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
