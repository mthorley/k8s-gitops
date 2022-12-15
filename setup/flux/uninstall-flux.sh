#!/bin/bash

export REPO_ROOT=$(git rev-parse --show-toplevel)

. "$REPO_ROOT"/.env

flux uninstall --namespace=flux-system
