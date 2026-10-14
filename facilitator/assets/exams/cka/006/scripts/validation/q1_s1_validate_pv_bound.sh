#!/bin/bash
pass() { echo "✅ $1"; exit 0; }
fail() { echo "❌ $1"; exit 1; }
V=$(kubectl get pv orders-pv -o jsonpath='{.status.phase}|{.spec.claimRef.namespace}/{.spec.claimRef.name}|{.spec.persistentVolumeReclaimPolicy}' 2>/dev/null) || fail "PV orders-pv not found"
[ "$(kubectl get pv orders-pv -o jsonpath='{.metadata.uid}')" = "$(kubectl get ns orders -o jsonpath='{.metadata.annotations.ckx\.io/orders-pv-uid}')" ] || fail "orders-pv was deleted and recreated (its data would be lost)"
[ "$V" = "Bound|orders/orders-data|Retain" ] || fail "orders-pv is not Bound to orders/orders-data with Retain ($V)"
P=$(kubectl get pvc orders-data -n orders -o jsonpath='{.spec.volumeName}|{.spec.storageClassName}|{.spec.resources.requests.storage}' 2>/dev/null) || fail "PVC orders-data not found"
[ "$P" = "orders-pv|manual|500Mi" ] && pass "PVC orders-data bound to orders-pv" || fail "PVC orders-data incorrect: $P"
