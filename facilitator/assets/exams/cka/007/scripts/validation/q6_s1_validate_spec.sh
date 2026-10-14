#!/bin/bash
pass() { echo "✅ $1"; exit 0; }
fail() { echo "❌ $1"; exit 1; }
P=$(kubectl get pod vault-agent -n vault -o json 2>/dev/null) || fail "Pod vault-agent not found"
V=$(echo "$P" | jq -c '[.spec.volumes[] | select(.secret.secretName=="app-secrets")][0]')
[ "$V" != "null" ] || fail "No volume from Secret app-secrets"
echo "$V" | jq -e '(.secret.items // []) | length == 1 and .[0].key=="api-token" and .[0].path=="token"' >/dev/null || fail "Only the key api-token must be projected, as the file 'token'"
echo "$V" | jq -e '((.secret.items[0].mode // .secret.defaultMode) == 256)' >/dev/null || fail "File mode must be 0400"
VN=$(echo "$V" | jq -r '.name')
echo "$P" | jq -e --arg v "$VN" '.spec.containers[0].volumeMounts[] | select(.name==$v) | .mountPath=="/etc/app"' >/dev/null \
  && pass "Secret mounted correctly" || fail "The secret volume must be mounted at /etc/app"
