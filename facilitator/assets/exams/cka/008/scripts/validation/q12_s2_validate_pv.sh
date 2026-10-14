#!/bin/bash
pass() { echo "✅ $1"; exit 0; }
fail() { echo "❌ $1"; exit 1; }
P=$(kubectl get pv ssd-pv-1 -o json 2>/dev/null) || fail "PersistentVolume ssd-pv-1 not found"
echo "$P" | jq -e '.spec.capacity.storage=="2Gi" and .spec.accessModes==["ReadWriteOnce"] and .spec.persistentVolumeReclaimPolicy=="Retain" and .spec.storageClassName=="local-ssd" and .spec.local.path=="/mnt/disks/ssd1"' >/dev/null || fail "ssd-pv-1 must be a local volume at /mnt/disks/ssd1, 2Gi, RWO, Retain, class local-ssd"
echo "$P" | jq -e '[.spec.nodeAffinity.required.nodeSelectorTerms[].matchExpressions[] | select(.key=="kubernetes.io/hostname" and .operator=="In" and .values==["k3d-cluster-agent-1"])] | length == 1' >/dev/null \
  && pass "Local PV correct" || fail "ssd-pv-1 needs nodeAffinity kubernetes.io/hostname In [k3d-cluster-agent-1]"
