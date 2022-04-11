helm repo add vector https://helm.vector.dev
helm repo update

helm template vector vector/vector -f values.yaml> vector-stack.yaml

unifi.syslog.orig: 192.168.2.12
