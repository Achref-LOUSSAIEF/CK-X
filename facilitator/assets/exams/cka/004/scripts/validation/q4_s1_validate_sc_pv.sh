#!/bin/bash
pass() { echo "✅ $1"; exit 0; }
fail() { echo "❌ $1"; exit 1; }
P=$(kubectl get sc fast-ssd -o jsonpath='{.provisioner}' 2>/dev/null) || fail "StorageClass fast-ssd not found"
[ "$P" = "kubernetes.io/no-provisioner" ] || fail "fast-ssd provisioner is $P"
V=$(kubectl get pv db-pv -o jsonpath='{.spec.capacity.storage}|{.spec.accessModes[*]}|{.spec.storageClassName}|{.spec.hostPath.path}' 2>/dev/null) || fail "PV db-pv not found"
[ "$V" = "5Gi|ReadWriteMany|fast-ssd|/mnt/db-data" ] && pass "SC and PV correct" || fail "PV db-pv incorrect: $V"
