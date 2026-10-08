#!/bin/bash
pass() { echo "✅ $1"; exit 0; }
fail() { echo "❌ $1"; exit 1; }
V=$(kubectl get sc ssd-provisioner -o jsonpath='{.provisioner}|{.volumeBindingMode}|{.reclaimPolicy}' 2>/dev/null) || fail "StorageClass ssd-provisioner not found"
[ "$V" = "rancher.io/local-path|WaitForFirstConsumer|Delete" ] && pass "StorageClass correct" || fail "StorageClass incorrect: $V"
