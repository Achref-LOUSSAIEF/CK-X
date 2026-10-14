#!/bin/bash
pass() { echo "✅ $1"; exit 0; }
fail() { echo "❌ $1"; exit 1; }
P=$(kubectl get pod writer -n payments -o json 2>/dev/null) || fail "Pod writer not found"
VN=$(echo "$P" | jq -r '[.spec.volumes[]? | select(.persistentVolumeClaim.claimName=="data-dyn")][0].name')
[ "$VN" != "null" ] || fail "writer does not use data-dyn"
echo "$P" | jq -e --arg v "$VN" '[.spec.containers[0].volumeMounts[]? | select(.name==$v and .mountPath=="/data")] | length == 1' >/dev/null || fail "data-dyn must be mounted at /data"
kubectl wait --for=condition=Ready pod/writer -n payments --timeout=30s >/dev/null 2>&1 && pass "writer running" || fail "writer is not Ready"
