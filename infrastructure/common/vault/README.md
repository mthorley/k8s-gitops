
## vault-stack.yaml generation

```
helm repo add hashicorp https://helm.releases.hashicorp.com

helm template vault hashicorp/vault \
    --set 'server.ha.enabled=true' \
    --set 'server.ha.raft.enabled=true' \
    --set 'injector.enabled=false' \
    --set 'server.dataStorage.storageClass=managed-nfs-storage' \
    --namespace='vault' > vault-stack.yaml
```

helm template vault hashicorp/vault \
    --namespace='vault' \
    --values values.yaml > vault-stack.yaml
```
