#!/bin/bash
pass() { echo "✅ $1"; exit 0; }
fail() { echo "❌ $1"; exit 1; }
S=$(helm status monitoring-stack -n monitoring -o json 2>/dev/null | jq -r '.info.status') || true
[ "$S" = "deployed" ] || fail "Release monitoring-stack not deployed in namespace monitoring"
V=$(helm get values monitoring-stack -n monitoring --all -o json 2>/dev/null)
echo "$V" | jq -e '(.replica_count|tostring)=="3" and .storage_size=="50Gi" and .persistence.enabled==true' >/dev/null \
  && pass "Values overridden" || fail "Values not overridden correctly: $(echo "$V" | jq -c '{replica_count,storage_size,persistence}')"
