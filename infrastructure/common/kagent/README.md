helm template kagent-crds oci://ghcr.io/kagent-dev/kagent/helm/kagent-crds \
    --namespace kagent \
    --create-namespace > kagent-crds-stack.yaml

helm template kagent oci://ghcr.io/kagent-dev/kagent/helm/kagent \
    --namespace kagent > kagent-stack.yaml