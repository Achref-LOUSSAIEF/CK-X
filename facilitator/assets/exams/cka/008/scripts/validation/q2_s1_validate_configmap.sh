#!/bin/bash
pass() { echo "✅ $1"; exit 0; }
fail() { echo "❌ $1"; exit 1; }
kubectl get cm frontend-config-v1 -n frontend >/dev/null 2>&1 || fail "frontend-config-v1 was deleted"
C=$(kubectl get cm frontend-config-v2 -n frontend -o json 2>/dev/null) || fail "ConfigMap frontend-config-v2 not found"
echo "$C" | jq -e '.immutable==true and .data.LOG_LEVEL=="debug" and .data.THEME=="dark"' >/dev/null \
  && pass "frontend-config-v2 correct" || fail "frontend-config-v2 must be immutable with LOG_LEVEL=debug and THEME=dark"
