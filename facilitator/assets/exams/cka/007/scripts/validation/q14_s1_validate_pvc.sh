#!/bin/bash
pass() { echo "✅ $1"; exit 0; }
fail() { echo "❌ $1"; exit 1; }
V=$(kubectl get pvc archive-data -n archive -o jsonpath='{.spec.storageClassName}|{.spec.resources.requests.storage}|{.spec.accessModes[0]}|{.status.phase}' 2>/dev/null) || fail "PVC archive-data not found"
[ "$V" = "local-path|1Gi|ReadWriteOnce|Bound" ] && pass "PVC correct" || fail "PVC archive-data incorrect: $V"
