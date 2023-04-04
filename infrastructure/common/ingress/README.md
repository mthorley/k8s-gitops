## Helm 

helm template ingress-nginx \
  --repo https://kubernetes.github.io/ingress-nginx \
  --namespace ingress-nginx --create-namespace > ingress-nginx-stack.yaml

## How to add an ingress with TLS

### Create k8s resources
1. Create an [internal service](/apps/common/node-red/service.yaml)
2. Create a [certificate issuer](/apps/common/node-red/cert-issuer.yaml)
3. Create a [certificate](/apps/common/node-red/cert.yaml)
4. Create an [ingress resource](/apps/common/node-red/ingress.yaml)
5. Add above to kustomize.yaml

### Configure vault pki
1. Add permissions to the [vault terraform ](/setup/vault/pki.tf) for the k8s service account to generate cert:

```
resource "vault_kubernetes_auth_backend_role" "nodered-issuer" {
  backend                          = vault_auth_backend.kubernetes.path
  role_name                        = "nodered-issuer-cert-role"
  bound_service_account_names      = ["nodered"]
  bound_service_account_namespaces = ["node-red"]
  token_ttl                        = 86400
  token_policies                   = ["issuer-cert-policy"]
}
```

Ensure 
 - the ```role``` in the cert-issuer maps to the role_name above
 - service account name and namespace are correct

 ### Update unifi dns route 
 
 Ensure unifi dns is configured to route the host to nginx controller external LB

 1. /host/.internal.com needs to be added to github.com/mthorley/network-management/unifi
 2. terraform apply to generate gateway.json
 3. ssh into 192.168.3.111 
 4. update gateway.json under ```/mnt/ssd/unifi-controller-unifi-data-pvc-8235653e-4eaf-4fb8-b5dd-99ea39dd826d/data/sites/default```
