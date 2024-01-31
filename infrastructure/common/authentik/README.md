
## Install

helm repo add authentik https://charts.goauthentik.io
helm repo update
helm template authentik authentik/authentik -f values.yaml \
  --namespace authentik \
  --create-namespace > authentik-stack.yaml

helm chart does not respect namespaces, so the stack has been manually applied.
