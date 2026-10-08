#!/bin/bash
pass() { echo "✅ $1"; exit 0; }
fail() { echo "❌ $1"; exit 1; }
D=$(kubectl get deploy db-client -n app-secrets -o json 2>/dev/null) || fail "Deployment db-client not found"
for p in "DB_USERNAME username" "DB_PASSWORD password" "DB_DATABASE database"; do
  set -- $p
  echo "$D" | jq -e --arg n "$1" --arg k "$2" '.spec.template.spec.containers[0].env[]? | select(.name==$n) | .valueFrom.secretKeyRef.name=="db-creds" and .valueFrom.secretKeyRef.key==$k' >/dev/null \
    || fail "Env $1 must come from secret db-creds key $2"
done
echo "$D" | jq -e '[.spec.template.spec.volumes[]? | select(.secret != null)] | length == 0' >/dev/null && pass "Env vars configured" || fail "Secret must not be mounted as a volume"
