#!/bin/bash
pass() { echo "✅ $1"; exit 0; }
fail() { echo "❌ $1"; exit 1; }
D=$(kubectl get deploy db-app -n databases -o json 2>/dev/null) || fail "Deployment db-app not found"
echo "$D" | jq -e '.spec.template.spec.volumes[]? | select(.name=="data") | .persistentVolumeClaim.claimName=="db-storage"' >/dev/null || fail "Volume data must use PVC db-storage"
echo "$D" | jq -e '.spec.template.spec.containers[0].volumeMounts[]? | select(.name=="data") | .mountPath=="/data"' >/dev/null || fail "Volume data must be mounted at /data"
kubectl rollout status deploy/db-app -n databases --timeout=20s >/dev/null 2>&1
R=$(kubectl get deploy db-app -n databases -o jsonpath='{.status.readyReplicas}')
[ "${R:-0}" -eq 2 ] && pass "db-app uses the PVC" || fail "db-app Ready replicas: ${R:-0}/2"
