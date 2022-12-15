#!/bin/bash

# See https://github.com/fluxcd/flux2/issues/1462

export REPO_ROOT=$(git rev-parse --show-toplevel)

. "$REPO_ROOT"/.env

flux bootstrap github --owner=mthorley --repository=k8s-gitops --path=clusters/staging --personal --ssh-key-algorithm=ecdsa
