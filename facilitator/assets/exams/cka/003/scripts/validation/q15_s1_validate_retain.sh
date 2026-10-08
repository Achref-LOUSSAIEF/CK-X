#!/bin/bash
pass() { echo "✅ $1"; exit 0; }
fail() { echo "❌ $1"; exit 1; }
PV=$(kubectl get pvc ledger-data -n storage-ops -o jsonpath='{.spec.volumeName}' 2>/dev/null)
[ -n "$PV" ] || fail "PVC ledger-data is missing or not bound"
P=$(kubectl get pv "$PV" -o jsonpath='{.spec.persistentVolumeReclaimPolicy}')
[ "$P" = "Retain" ] && pass "$PV reclaim policy is Retain" || fail "$PV reclaim policy is $P"
