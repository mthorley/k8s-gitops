#!/bin/bash
# Manually install a Home Assistant custom component (non-HACS) onto the
# home-assistant-config PVC by copying it into the running pod's /config
# and restarting the deployment.
#
# Usage:
#   ./install-custom-component.sh <git-repo-url> [component-name] [namespace]
#
# Examples:
#   ./install-custom-component.sh https://github.com/nathanvdh/homeassistant-airtouch2plus
#   ./install-custom-component.sh https://github.com/nathanvdh/homeassistant-airtouch2plus airtouch2plus homeassistant
#
# The repo must contain a custom_components/<component-name>/ directory
# (the standard HA custom component layout). If component-name is omitted,
# it is auto-detected when the repo has exactly one folder under
# custom_components/.

set -euo pipefail

REPO_URL="${1:?Usage: $0 <git-repo-url> [component-name] [namespace]}"
COMPONENT_NAME="${2:-}"
NAMESPACE="${3:-homeassistant}"

WORKDIR=$(mktemp -d)
trap 'rm -rf "$WORKDIR"' EXIT

echo "==> Cloning $REPO_URL"
git clone --depth 1 --quiet "$REPO_URL" "$WORKDIR/repo"

if [[ -z "$COMPONENT_NAME" ]]; then
  CANDIDATES=("$WORKDIR"/repo/custom_components/*/)
  if [[ ${#CANDIDATES[@]} -ne 1 ]]; then
    echo "Could not auto-detect a single component under custom_components/, pass component-name explicitly." >&2
    exit 1
  fi
  COMPONENT_NAME=$(basename "${CANDIDATES[0]}")
  echo "==> Detected component: $COMPONENT_NAME"
fi

SRC_DIR="$WORKDIR/repo/custom_components/$COMPONENT_NAME"
if [[ ! -d "$SRC_DIR" ]]; then
  echo "custom_components/$COMPONENT_NAME not found in $REPO_URL" >&2
  exit 1
fi

echo "==> Locating home-assistant pod in namespace '$NAMESPACE'"
POD=$(kubectl get pod -n "$NAMESPACE" -l app.kubernetes.io/name=home-assistant -o jsonpath='{.items[0].metadata.name}')
if [[ -z "$POD" ]]; then
  echo "No home-assistant pod found in namespace '$NAMESPACE'" >&2
  exit 1
fi
echo "==> Found pod: $POD"

echo "==> Copying $COMPONENT_NAME into $POD:/config/custom_components/$COMPONENT_NAME"
# Clear any previous install first: `kubectl cp <dir> pod:<existing-dir>` nests
# the source inside the destination rather than populating it, so the target
# must not already exist when cp runs.
kubectl exec -n "$NAMESPACE" "$POD" -- rm -rf "/config/custom_components/$COMPONENT_NAME"
kubectl cp "$SRC_DIR" "$NAMESPACE/$POD:/config/custom_components/" --no-preserve=true

echo "==> Restarting deployment/home-assistant to load the new component"
kubectl rollout restart deployment/home-assistant -n "$NAMESPACE"
kubectl rollout status deployment/home-assistant -n "$NAMESPACE"

cat <<EOF

Done. Next steps:
  1. In Home Assistant: Settings -> Devices & Services -> Add Integration -> search "$COMPONENT_NAME".
  2. If the component needs to reach a host/CIDR not already allowed, add it to
     apps/common/homeassistant/allow-ext-egress-netpol.yaml (local LAN) or
     apps/common/homeassistant/allow-ext-egress-components-netpol.yaml (external FQDNs).

Note: /config lives on the home-assistant-config PVC, not in git, so this
install is not tracked by GitOps and must be re-run if the PVC is recreated.
EOF
