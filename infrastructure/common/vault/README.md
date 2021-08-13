
helm template vault hashicorp/vault --set 'server.ha.enabled=true' --set 'server.ha.raft.enabled=true' --set 'injector.enabled=true' --set 'server.dataStorage.storageClass=managed-nfs-storage' --namespace='vault' > vault-stack.yaml
