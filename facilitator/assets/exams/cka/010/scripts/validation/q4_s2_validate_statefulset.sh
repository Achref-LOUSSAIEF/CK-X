#!/bin/bash
pass() { echo "✅ $1"; exit 0; }
fail() { echo "❌ $1"; exit 1; }
S=$(kubectl get sts db -n media -o json 2>/dev/null) || fail "StatefulSet db not found"
echo "$S" | jq -e '.spec.replicas==2 and .spec.serviceName=="db" and .spec.template.spec.containers[0].image=="redis:7.2" and .spec.template.metadata.labels.app=="db"' >/dev/null || fail "db needs 2 replicas, serviceName db, image redis:7.2, label app=db"
kubectl rollout status sts/db -n media --timeout=60s >/dev/null 2>&1
R=$(kubectl get sts db -n media -o jsonpath='{.status.readyReplicas}')
[ "${R:-0}" -eq 2 ] && pass "db-0 and db-1 ready" || fail "db has ${R:-0}/2 ready Pods"
