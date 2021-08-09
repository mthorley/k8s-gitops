
https://github.com/bitnami/charts/tree/master/bitnami/mongodb

architecture=replicaset
  storageClass: "nfs-storage"
  namespaceOverride: "mongodb"

helm template mongodb bitnami/mongodb -f values.yaml
