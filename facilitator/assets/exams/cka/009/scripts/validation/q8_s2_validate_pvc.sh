#!/bin/bash
pass() { echo "✅ $1"; exit 0; }
fail() { echo "❌ $1"; exit 1; }
V=$(kubectl get pvc pvc-data -n default -o jsonpath='{.spec.storageClassName}|{.spec.resources.requests.storage}|{.status.phase}|{.spec.volumeName}' 2>/dev/null) || fail "PVC pvc-data not found"
[ "$V" = "manual|500Mi|Bound|pv-data" ] && pass "pvc-data bound" || fail "pvc-data incorrect (class|size|phase|volume): $V"
