#!/bin/bash
pass() { echo "✅ $1"; exit 0; }
fail() { echo "❌ $1"; exit 1; }
F=/tmp/exam/q1/orders-db.yaml
grep -q "claimName: *orders-data" "$F" || fail "$F does not reference the PVC orders-data"
D=$(kubectl get deploy orders-db -n orders -o json 2>/dev/null) || fail "Deployment orders-db not found"
echo "$D" | jq -e '.spec.template.spec.volumes[]? | select(.name=="data") | .persistentVolumeClaim.claimName=="orders-data"' >/dev/null || fail "Volume data must use PVC orders-data"
echo "$D" | jq -e '.spec.template.spec.containers[0].volumeMounts[]? | select(.name=="data") | .mountPath=="/var/lib/mysql"' >/dev/null || fail "data must be mounted at /var/lib/mysql"
kubectl rollout status deploy/orders-db -n orders --timeout=30s >/dev/null 2>&1
A=$(kubectl get deploy orders-db -n orders -o jsonpath='{.status.availableReplicas}')
[ "${A:-0}" -ge 1 ] && pass "orders-db available with its data" || fail "orders-db is not available"
