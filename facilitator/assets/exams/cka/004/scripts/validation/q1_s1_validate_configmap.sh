#!/bin/bash
pass() { echo "✅ $1"; exit 0; }
fail() { echo "❌ $1"; exit 1; }
V=$(kubectl get cm app-config -n production -o jsonpath='{.data.config\.yaml}' 2>/dev/null) || fail "ConfigMap app-config not found"
[ "$(echo "$V" | sed 's/[[:space:]]*$//' | grep -v '^$')" = "database_host: postgres.production.svc.cluster.local" ] \
  && pass "ConfigMap content correct" || fail "Key config.yaml has wrong content: $V"
