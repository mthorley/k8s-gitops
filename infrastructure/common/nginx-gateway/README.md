
helm template ngf oci://ghcr.io/nginx/charts/nginx-gateway-fabric --create-namespace -n nginx-gateway > nginx-gateway-fabric-stack.yaml

curl https://raw.githubusercontent.com/nginx/nginx-gateway-fabric/v2.3.0/deploy/crds.yaml > nginx-crds.yaml

https://github.com/kubernetes-sigs/gateway-api/releases > gateway-crds.yaml

Current nginx target: v2.30

ocirepository and helmrelease to hard to coordinate with CRDs.