#!/bin/bash
pass() { echo "✅ $1"; exit 0; }
fail() { echo "❌ $1"; exit 1; }
S=$(kubectl get svc legacy-db -n integrations -o json 2>/dev/null) || fail "Service legacy-db not found"
echo "$S" | jq -e '(.spec.selector // {} | length == 0) and .spec.type=="ClusterIP" and .spec.ports[0].port==5432' >/dev/null \
  && pass "Service correct" || fail "legacy-db must be a ClusterIP Service on port 5432 without a selector"
