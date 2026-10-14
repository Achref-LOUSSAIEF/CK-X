#!/bin/bash
pass() { echo "✅ $1"; exit 0; }
fail() { echo "❌ $1"; exit 1; }
V=$(kubectl get sc fast-retain -o jsonpath='{.provisioner}|{.reclaimPolicy}|{.volumeBindingMode}|{.allowVolumeExpansion}' 2>/dev/null) || fail "StorageClass fast-retain not found"
[ "$V" = "rancher.io/local-path|Retain|WaitForFirstConsumer|true" ] && pass "fast-retain correct" || fail "fast-retain incorrect: $V"
