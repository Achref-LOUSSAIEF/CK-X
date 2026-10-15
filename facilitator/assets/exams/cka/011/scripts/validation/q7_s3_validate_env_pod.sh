#!/bin/bash
pass() { echo "✅ $1"; exit 0; }
fail() { echo "❌ $1"; exit 1; }
P=$(kubectl get pod secret-env -n secret-lab -o json 2>/dev/null) || fail "Pod secret-env not found"
echo "$P" | jq -e '[.spec.containers[].env[]? | select(.name=="APP_PASSWORD" and .valueFrom.secretKeyRef.name=="app-secret" and .valueFrom.secretKeyRef.key=="password")] | length > 0' >/dev/null || fail "APP_PASSWORD does not come from the key password of app-secret"
kubectl wait --for=condition=Ready pod/secret-env -n secret-lab --timeout=30s >/dev/null 2>&1 || fail "Pod secret-env is not Ready"
[ "$(kubectl exec -n secret-lab secret-env -- printenv APP_PASSWORD 2>/dev/null)" = "n0t-s0-s3cret" ]   && pass "APP_PASSWORD is set" || fail "APP_PASSWORD is not set in the container"
