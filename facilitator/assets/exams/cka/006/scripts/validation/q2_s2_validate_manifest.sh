#!/bin/bash
pass() { echo "✅ $1"; exit 0; }
fail() { echo "❌ $1"; exit 1; }
F=/tmp/exam/q2/argocd.yaml
[ -s "$F" ] || fail "$F not found or empty"
grep -q "helm.sh/chart: argo-cd-7.7.3" "$F" || fail "$F is not rendered from argo-cd chart version 7.7.3"
grep -Eq "^kind: CustomResourceDefinition" "$F" && fail "$F still contains CustomResourceDefinitions"
J=$(kubectl create --dry-run=client -o json -f "$F" 2>/dev/null | jq -c 'if .kind=="List" then .items[] else . end | select(.kind=="Deployment" and .metadata.name=="argocd-server")')
[ -n "$J" ] || fail "$F has no Deployment argocd-server (release name must be argocd)"
[ "$(echo "$J" | jq -r '.metadata.namespace')" = "argocd" ] && pass "Manifest rendered correctly" || fail "Manifest is not rendered for the argocd namespace"
