#!/bin/bash
pass() { echo "✅ $1"; exit 0; }
fail() { echo "❌ $1"; exit 1; }
kubectl rollout status deploy/db-client -n app-secrets --timeout=20s >/dev/null 2>&1 || fail "db-client not ready"
[ "$(kubectl exec deploy/db-client -n app-secrets -- printenv DB_USERNAME 2>/dev/null)" = "dbuser" ] || fail "DB_USERNAME not set in the Pod"
[ "$(kubectl exec deploy/db-client -n app-secrets -- printenv DB_PASSWORD 2>/dev/null)" = "secret123" ] || fail "DB_PASSWORD not set in the Pod"
kubectl logs deploy/db-client -n app-secrets 2>/dev/null | grep -q secret123 && fail "The password appears in the Pod logs"
pass "Env vars available, not logged"
