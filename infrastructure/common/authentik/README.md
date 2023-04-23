

## Install

helm repo add authentik https://charts.goauthentik.io
helm repo update
helm template authentik authentik/authentik -f values.yaml \
  --namespace authentik \
  --create-namespace > authentik-stack.yaml

helm chart does not respect namespaces, so the stack has been manually.

## Initial Setup

Admin: https://auth.internal.com/if/flow/initial-setup/

Terraform token: Navigate to admin user | Token and App Passwords, create a token
