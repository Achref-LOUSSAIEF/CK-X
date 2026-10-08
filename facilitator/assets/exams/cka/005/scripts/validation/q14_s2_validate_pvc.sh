#!/bin/bash
pass() { echo "✅ $1"; exit 0; }
fail() { echo "❌ $1"; exit 1; }
V=$(kubectl get pvc my-ssd-claim -n dyn-storage -o jsonpath='{.spec.storageClassName}|{.spec.resources.requests.storage}|{.status.phase}' 2>/dev/null) || fail "PVC my-ssd-claim not found"
[ "$V" = "ssd-provisioner|20Gi|Bound" ] || fail "PVC incorrect: $V"
PV=$(kubectl get pvc my-ssd-claim -n dyn-storage -o jsonpath='{.spec.volumeName}')
PB=$(kubectl get pv "$PV" -o jsonpath='{.metadata.annotations.pv\.kubernetes\.io/provisioned-by}')
[ "$PB" = "rancher.io/local-path" ] && pass "PV $PV provisioned dynamically" || fail "PV $PV was not dynamically provisioned"
