#!/bin/bash

# See https://github.com/fluxcd/flux2/issues/1462

export REPO_ROOT=$(git rev-parse --show-toplevel)

. "$REPO_ROOT"/.env

# Bootstraps the `cluster-vars` Secret that clusters/production/*.yaml
# Kustomizations read via postBuild.substituteFrom.
kubectl create namespace flux-system --dry-run=client -o yaml | kubectl apply -f -
kubectl -n flux-system create secret generic cluster-vars \
  --from-literal=domain="$TF_VAR_INTERNAL_DOMAIN" \
  --from-literal=cluster_tz="$CLUSTER_TZ" \
  --dry-run=client -o yaml | kubectl apply -f -

# staging
flux bootstrap github --owner=mthorley --repository=k8s-gitops --path=clusters/staging --personal --ssh-key-algorithm=ecdsa

# production
#flux bootstrap github --owner=mthorley --repository=k8s-gitops --path=clusters/production --personal --ssh-key-algorithm=ecdsa
