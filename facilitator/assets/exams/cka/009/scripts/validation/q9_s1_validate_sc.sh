#!/bin/bash
pass() { echo "✅ $1"; exit 0; }
fail() { echo "❌ $1"; exit 1; }
S=$(kubectl get sc fast-local -o json 2>/dev/null) || fail "StorageClass fast-local not found"
echo "$S" | jq -e '.provisioner=="rancher.io/local-path" and .volumeBindingMode=="WaitForFirstConsumer" and (.reclaimPolicy // "Delete")=="Delete" and (.metadata.annotations["storageclass.kubernetes.io/is-default-class"] // "false")!="true"' >/dev/null \
  && pass "fast-local correct" || fail "fast-local must use rancher.io/local-path, WaitForFirstConsumer, Delete, and not be the default"
