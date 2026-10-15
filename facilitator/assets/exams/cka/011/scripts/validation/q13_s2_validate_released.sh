#!/bin/bash
pass() { echo "✅ $1"; exit 0; }
fail() { echo "❌ $1"; exit 1; }
kubectl get pvc scratch -n retain-lab >/dev/null 2>&1 && fail "The PVC scratch still exists"
kubectl get pod writer -n retain-lab >/dev/null 2>&1 && fail "The Pod writer still exists"
kubectl get pv -o json | jq -e '[.items[] | select(.spec.storageClassName=="keep-local" and .spec.claimRef.namespace=="retain-lab" and .spec.claimRef.name=="scratch" and .spec.persistentVolumeReclaimPolicy=="Retain" and .status.phase=="Released")] | length > 0' >/dev/null   && pass "The PV of scratch is kept in the Released state" || fail "No Released keep-local PV that belonged to retain-lab/scratch"
