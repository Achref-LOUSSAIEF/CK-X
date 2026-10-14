#!/bin/bash
# Validate the Kustomize base/overlay files and what the overlay renders to.
# The overlay may use any valid technique (replicas field, strategic-merge or JSON patch).
set -e

BASE_DIR="/tmp/exam/kustomize/base"
OVERLAY_DIR="/tmp/exam/kustomize/overlays/production"

for f in "$BASE_DIR/kustomization.yaml" "$BASE_DIR/deployment.yaml" "$OVERLAY_DIR/kustomization.yaml"; do
    if [[ ! -f "$f" ]]; then
        echo "Missing file: $f"
        exit 1
    fi
done

if ! grep -q "deployment.yaml" "$BASE_DIR/kustomization.yaml"; then
    echo "Base kustomization.yaml does not list deployment.yaml"
    exit 1
fi

RENDERED=$(kubectl kustomize "$OVERLAY_DIR" 2>&1) || {
    echo "Overlay does not build: $RENDERED"
    exit 1
}

DEPLOY=$(echo "$RENDERED" | kubectl create --dry-run=client -o json -f - 2>/dev/null \
    | jq -c 'if .kind == "List" then .items[] else . end | select(.kind == "Deployment" and .metadata.name == "nginx")')
if [[ -z "$DEPLOY" ]]; then
    echo "Overlay does not render a Deployment named nginx"
    exit 1
fi

if [[ "$(echo "$DEPLOY" | jq -r '.spec.replicas')" != "3" ]]; then
    echo "Overlay does not set replicas to 3"
    exit 1
fi
if [[ "$(echo "$DEPLOY" | jq -r '.metadata.labels.environment')" != "production" ]]; then
    echo "Overlay does not add the label environment=production"
    exit 1
fi
if [[ "$(echo "$DEPLOY" | jq -r '.metadata.namespace')" != "kustomize" ]]; then
    echo "Overlay does not set the namespace kustomize"
    exit 1
fi

echo "Kustomize files validation successful"
exit 0
