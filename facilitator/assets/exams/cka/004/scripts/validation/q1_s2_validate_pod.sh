#!/bin/bash
pass() { echo "✅ $1"; exit 0; }
fail() { echo "❌ $1"; exit 1; }
IMG=$(kubectl get pod app-frontend -n production -o jsonpath='{.spec.containers[0].image}' 2>/dev/null) || fail "Pod app-frontend not found"
[ "$IMG" = "busybox:1.36" ] || fail "Image changed to $IMG"
kubectl wait --for=condition=Ready pod/app-frontend -n production --timeout=15s >/dev/null 2>&1 || fail "Pod is not Ready"
OUT=$(kubectl exec app-frontend -n production -- cat /etc/app/config.yaml 2>/dev/null)
echo "$OUT" | grep -q "database_host: postgres.production.svc.cluster.local" && pass "Config file mounted" || fail "/etc/app/config.yaml missing or wrong"
