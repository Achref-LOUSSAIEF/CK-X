#!/bin/bash
pass() { echo "✅ $1"; exit 0; }
fail() { echo "❌ $1"; exit 1; }
P=$(kubectl get pod data-pod -n default -o json 2>/dev/null) || fail "Pod data-pod not found"
VN=$(echo "$P" | jq -r '[.spec.volumes[]? | select(.persistentVolumeClaim.claimName=="pvc-data")][0].name')
[ "$VN" != "null" ] || fail "data-pod does not use pvc-data"
echo "$P" | jq -e --arg v "$VN" '[.spec.containers[0].volumeMounts[]? | select(.name==$v and .mountPath=="/usr/share/nginx/html")] | length == 1' >/dev/null || fail "pvc-data must be mounted at /usr/share/nginx/html"
kubectl wait --for=condition=Ready pod/data-pod -n default --timeout=30s >/dev/null 2>&1 && pass "data-pod running" || fail "data-pod is not Ready"
