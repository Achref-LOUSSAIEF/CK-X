#!/bin/bash
pass() { echo "✅ $1"; exit 0; }
fail() { echo "❌ $1"; exit 1; }
V=$(kubectl get pv pv-data -o json 2>/dev/null) || fail "PersistentVolume pv-data not found"
echo "$V" | jq -e '.spec.capacity.storage=="1Gi" and (.spec.accessModes|index("ReadWriteOnce")) and .spec.hostPath.path=="/mnt/data" and .spec.storageClassName=="manual"' >/dev/null \
  && pass "pv-data correct" || fail "pv-data must be 1Gi, ReadWriteOnce, hostPath /mnt/data, storageClassName manual"
