#!/bin/bash
# Manually install a Home Assistant custom component (non-HACS) onto the
# home-assistant-config PVC by copying it into the running pod's /config
# and restarting the deployment.
#
# Usage:
#   ./install-custom-component.sh <source> [component-name] [namespace]
#
# <source> is either a git repo URL or a release-zip URL/path (anything ending
# in .zip). Examples:
#   ./install-custom-component.sh https://github.com/nathanvdh/homeassistant-airtouch2plus
#   ./install-custom-component.sh https://github.com/nathanvdh/homeassistant-airtouch2plus airtouch2plus homeassistant
#   ./install-custom-component.sh https://github.com/christiaangoossens/hass-oidc-auth/releases/download/v1.2.1/hass-oidc-auth.zip auth_oidc
#
# Prefer the release zip whenever the component publishes one - a project with
# "zip_release": true in hacs.json builds assets during its release workflow, so
# its git tree is incomplete and a clone installs something that breaks at
# runtime. hass-oidc-auth is the example: static/style.css is compiled from
# static/input.css at release time and is absent from git, so the welcome page
# 500s on a cloned install.
#
# Layouts handled:
#   - git clone, or a zip, containing custom_components/<component-name>/
#     (component-name auto-detected when there is exactly one such folder)
#   - a zip whose root IS the component (no custom_components/ prefix), as
#     produced by the HACS zip_release convention - component-name is then
#     required, since nothing in the archive names it

set -euo pipefail

SOURCE="${1:?Usage: $0 <git-repo-url|release-zip-url> [component-name] [namespace]}"
COMPONENT_NAME="${2:-}"
NAMESPACE="${3:-homeassistant}"

WORKDIR=$(mktemp -d)
trap 'rm -rf "$WORKDIR"' EXIT

if [[ "$SOURCE" == *.zip ]]; then
  ZIP="$WORKDIR/component.zip"
  if [[ "$SOURCE" == http://* || "$SOURCE" == https://* ]]; then
    echo "==> Downloading $SOURCE"
    curl -fsSL -o "$ZIP" "$SOURCE"
  else
    echo "==> Using local zip $SOURCE"
    cp "$SOURCE" "$ZIP"
  fi
  mkdir -p "$WORKDIR/unpack"
  unzip -q "$ZIP" -d "$WORKDIR/unpack"

  if [[ -d "$WORKDIR/unpack/custom_components" ]]; then
    # Zip of a whole repo: same shape as a clone from here on.
    ROOT="$WORKDIR/unpack"
  else
    # HACS zip_release: the archive root is the component itself, so it has to
    # be renamed to the component name before copying - the directory name is
    # what HA uses as the domain.
    if [[ -z "$COMPONENT_NAME" ]]; then
      echo "This zip has no custom_components/ directory, so its root is the component itself." >&2
      echo "Pass component-name explicitly, e.g. auth_oidc." >&2
      exit 1
    fi
    ROOT="$WORKDIR/root"
    mkdir -p "$ROOT/custom_components"
    mv "$WORKDIR/unpack" "$ROOT/custom_components/$COMPONENT_NAME"
  fi
else
  echo "==> Cloning $SOURCE"
  git clone --depth 1 --quiet "$SOURCE" "$WORKDIR/repo"
  ROOT="$WORKDIR/repo"
fi

if [[ -z "$COMPONENT_NAME" ]]; then
  CANDIDATES=("$ROOT"/custom_components/*/)
  if [[ ${#CANDIDATES[@]} -ne 1 ]]; then
    echo "Could not auto-detect a single component under custom_components/, pass component-name explicitly." >&2
    exit 1
  fi
  COMPONENT_NAME=$(basename "${CANDIDATES[0]}")
  echo "==> Detected component: $COMPONENT_NAME"
fi

SRC_DIR="$ROOT/custom_components/$COMPONENT_NAME"
if [[ ! -d "$SRC_DIR" ]]; then
  echo "custom_components/$COMPONENT_NAME not found in $SOURCE" >&2
  exit 1
fi

if [[ ! -f "$SRC_DIR/manifest.json" ]]; then
  echo "No manifest.json in $SRC_DIR - this does not look like a custom component." >&2
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
     (Components configured by YAML instead, such as auth_oidc, need their
     include adding to /config/configuration.yaml on the PVC - not this script.)
  2. If the component needs to reach a host/CIDR not already allowed, add it to
     apps/common/homeassistant/allow-ext-egress-netpol.yaml (local LAN) or
     apps/common/homeassistant/allow-ext-egress-components-netpol.yaml (external FQDNs).

Note: /config lives on the home-assistant-config PVC, not in git, so this
install is not tracked by GitOps and must be re-run if the PVC is recreated.
EOF
