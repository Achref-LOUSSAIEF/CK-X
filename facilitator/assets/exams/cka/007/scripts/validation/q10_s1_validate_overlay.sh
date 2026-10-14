#!/bin/bash
pass() { echo "✅ $1"; exit 0; }
fail() { echo "❌ $1"; exit 1; }
grep -q "image: nginx:1.25" /tmp/exam/q10/base/deployment.yaml || fail "The base was edited (it must keep nginx:1.25)"
O=/tmp/exam/q10/overlays/staging
[ -f "$O/kustomization.yaml" ] || fail "$O/kustomization.yaml not found"
R=$(kubectl kustomize "$O" 2>&1) || fail "Overlay does not build: $R"
J=$(echo "$R" | kubectl create --dry-run=client -o json -f - 2>/dev/null | jq -c 'if .kind=="List" then .items[] else . end')
echo "$J" | jq -se 'map(select(.kind=="Deployment" and .metadata.name=="staging-api" and .metadata.namespace=="staging" and .spec.replicas==2 and .spec.template.spec.containers[0].image=="nginx:1.27" and .metadata.labels.env=="staging")) | length == 1' >/dev/null || fail "Overlay must render Deployment staging-api in staging with 2 replicas, nginx:1.27 and label env=staging"
echo "$J" | jq -se 'map(select(.kind=="Service" and .metadata.name=="staging-api" and .metadata.namespace=="staging" and .metadata.labels.env=="staging")) | length == 1' >/dev/null \
  && pass "Overlay correct" || fail "Overlay must render Service staging-api in staging with label env=staging"
