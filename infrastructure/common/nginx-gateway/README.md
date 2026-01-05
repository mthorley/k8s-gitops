
helm template ngf oci://ghcr.io/nginx/charts/nginx-gateway-fabric --create-namespace -n nginx-gateway > nginx-gateway-fabric-stack.yaml

curl https://raw.githubusercontent.com/nginx/nginx-gateway-fabric/v2.3.0/deploy/crds.yaml > crds.yaml

Current target: v2.30

ocirepository and helmrelease to hard to coordinate with CRDs.