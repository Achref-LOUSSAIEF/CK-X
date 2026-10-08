#!/bin/bash
pass() { echo "✅ $1"; exit 0; }
fail() { echo "❌ $1"; exit 1; }
kubectl rollout status sts/database-cluster -n db-cluster --timeout=30s >/dev/null 2>&1
R=$(kubectl get sts database-cluster -n db-cluster -o jsonpath='{.status.readyReplicas}')
[ "${R:-0}" -eq 3 ] || fail "Ready replicas: ${R:-0}/3"
for i in 0 1 2; do
  [ "$(kubectl get pvc db-storage-database-cluster-$i -n db-cluster -o jsonpath='{.status.phase}' 2>/dev/null)" = "Bound" ] || fail "PVC db-storage-database-cluster-$i not Bound"
done
kubectl exec database-cluster-0 -n db-cluster -c postgres -- nslookup database-cluster-2.database-cluster.db-cluster.svc.cluster.local >/dev/null 2>&1 \
  && pass "StatefulSet running with stable DNS" || fail "database-cluster-2.database-cluster does not resolve"
