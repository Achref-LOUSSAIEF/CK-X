#!/bin/bash
pass() { echo "✅ $1"; exit 0; }
fail() { echo "❌ $1"; exit 1; }
D=$(kubectl get sc -o json | jq -r '.items[] | select(.metadata.annotations["storageclass.kubernetes.io/is-default-class"]=="true") | .metadata.name' | sort | tr '\n' ' ')
[ "$D" = "fast-retain " ] && pass "Only fast-retain is default" || fail "Default StorageClasses: '${D:-none}'"
