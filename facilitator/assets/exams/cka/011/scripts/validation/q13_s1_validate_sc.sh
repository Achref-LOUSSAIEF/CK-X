#!/bin/bash
pass() { echo "✅ $1"; exit 0; }
fail() { echo "❌ $1"; exit 1; }
S=$(kubectl get sc keep-local -o json 2>/dev/null) || fail "StorageClass keep-local not found"
echo "$S" | jq -e '.provisioner=="rancher.io/local-path" and .reclaimPolicy=="Retain" and .volumeBindingMode=="WaitForFirstConsumer"' >/dev/null || fail "keep-local must use rancher.io/local-path, Retain and WaitForFirstConsumer"
echo "$S" | jq -e '(.metadata.annotations["storageclass.kubernetes.io/is-default-class"] // "false") != "true"' >/dev/null   && pass "StorageClass keep-local" || fail "keep-local must not be the default StorageClass"
