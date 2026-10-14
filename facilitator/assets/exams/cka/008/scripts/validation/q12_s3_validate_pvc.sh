#!/bin/bash
pass() { echo "✅ $1"; exit 0; }
fail() { echo "❌ $1"; exit 1; }
V=$(kubectl get pvc ssd-claim -n localdisk -o jsonpath='{.spec.storageClassName}|{.spec.resources.requests.storage}|{.spec.accessModes[0]}' 2>/dev/null) || fail "PVC ssd-claim not found"
[ "$V" = "local-ssd|2Gi|ReadWriteOnce" ] && pass "PVC correct" || fail "ssd-claim incorrect: $V"
