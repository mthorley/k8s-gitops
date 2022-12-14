
## vault-stack.yaml generation

```
helm repo add hashicorp https://helm.releases.hashicorp.com
```

For ha  
```
helm template vault hashicorp/vault \
    --set 'server.ha.enabled=true' \
    --set 'server.ha.raft.enabled=true' \
    --set 'injector.enabled=false' \
    --set 'server.dataStorage.storageClass=managed-nfs-storage' \
    --namespace='vault' > vault-stack.yaml
```

For single instance - currently deployed
```
helm template vault hashicorp/vault \
    --namespace='vault' \
    --values values.yaml > vault-stack.yaml
```

## Gotchas

```kustomize.toolkit.fluxcd.io/substitute: disabled``` 

is required to avoid the fluxcd kustomize error

```
var substitution failed for 'vault': variable substitution failed: missing closing brace
```
as discussed here https://fluxcd.io/flux/components/kustomize/kustomization/#variable-substitution

