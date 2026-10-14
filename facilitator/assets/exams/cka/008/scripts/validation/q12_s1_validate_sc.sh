#!/bin/bash
pass() { echo "✅ $1"; exit 0; }
fail() { echo "❌ $1"; exit 1; }
V=$(kubectl get sc local-ssd -o jsonpath='{.provisioner}|{.volumeBindingMode}' 2>/dev/null) || fail "StorageClass local-ssd not found"
[ "$V" = "kubernetes.io/no-provisioner|WaitForFirstConsumer" ] && pass "StorageClass correct" || fail "local-ssd incorrect: $V"
