#!/bin/bash
pass() { echo "✅ $1"; exit 0; }
fail() { echo "❌ $1"; exit 1; }
V=$(kubectl get pvc db-storage -n databases -o jsonpath='{.status.phase}|{.spec.volumeName}|{.spec.accessModes[*]}|{.spec.storageClassName}|{.spec.resources.requests.storage}' 2>/dev/null) || fail "PVC db-storage not found"
[ "$V" = "Bound|db-pv|ReadWriteMany|fast-ssd|5Gi" ] && pass "PVC Bound" || fail "PVC incorrect: $V"
