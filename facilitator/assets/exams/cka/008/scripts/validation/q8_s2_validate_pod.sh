#!/bin/bash
pass() { echo "✅ $1"; exit 0; }
fail() { echo "❌ $1"; exit 1; }
P=$(kubectl get pod builder -n ci -o json 2>/dev/null) || fail "Pod builder not found"
echo "$P" | jq -e '.spec.serviceAccountName=="builder"' >/dev/null || fail "Pod builder must use the ServiceAccount builder"
echo "$P" | jq -e '[.spec.volumes[]? | select(.name|startswith("kube-api-access"))] | length == 0' >/dev/null || fail "The default API token is still mounted"
V=$(echo "$P" | jq -c '[.spec.volumes[]? | select(.projected.sources[]?.serviceAccountToken.audience=="vault")][0]')
[ "$V" != "null" ] || fail "No projected volume with a serviceAccountToken for audience vault"
echo "$V" | jq -e '.projected.sources[] | select(.serviceAccountToken) | .serviceAccountToken | .expirationSeconds==3600 and .path=="token"' >/dev/null || fail "The token must be valid 3600 seconds and use path 'token'"
VN=$(echo "$V" | jq -r .name)
echo "$P" | jq -e --arg v "$VN" '.spec.containers[0].volumeMounts[]? | select(.name==$v) | .mountPath=="/var/run/secrets/vault"' >/dev/null \
  && pass "Projected token configured" || fail "The projected volume must be mounted at /var/run/secrets/vault"
