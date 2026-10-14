#!/bin/bash
pass() { echo "✅ $1"; exit 0; }
fail() { echo "❌ $1"; exit 1; }
V=$(kubectl get pvc data-dyn -n payments -o jsonpath='{.spec.storageClassName}|{.spec.resources.requests.storage}|{.spec.accessModes[0]}|{.status.phase}' 2>/dev/null) || fail "PVC data-dyn not found"
[ "$V" = "local-dyn|2Gi|ReadWriteOnce|Bound" ] && pass "data-dyn Bound" || fail "data-dyn incorrect (class|size|mode|phase): $V"
