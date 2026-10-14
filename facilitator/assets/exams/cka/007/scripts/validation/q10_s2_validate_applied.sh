#!/bin/bash
pass() { echo "✅ $1"; exit 0; }
fail() { echo "❌ $1"; exit 1; }
D=$(kubectl get deploy staging-api -n staging -o json 2>/dev/null) || fail "Deployment staging-api not found in staging (did you apply the overlay?)"
echo "$D" | jq -e '.spec.template.spec.containers[0].image=="nginx:1.27" and .metadata.labels.env=="staging"' >/dev/null || fail "Applied Deployment does not match the overlay"
kubectl get svc staging-api -n staging >/dev/null 2>&1 || fail "Service staging-api not found"
kubectl rollout status deploy/staging-api -n staging --timeout=30s >/dev/null 2>&1
R=$(kubectl get deploy staging-api -n staging -o jsonpath='{.status.readyReplicas}')
[ "${R:-0}" -eq 2 ] && pass "staging-api running" || fail "staging-api Ready replicas: ${R:-0}/2"
