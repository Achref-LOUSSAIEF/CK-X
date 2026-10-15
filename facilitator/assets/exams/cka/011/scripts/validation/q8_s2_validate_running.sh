#!/bin/bash
pass() { echo "✅ $1"; exit 0; }
fail() { echo "❌ $1"; exit 1; }
kubectl rollout status deploy/cms -n blog --timeout=60s >/dev/null 2>&1 || fail "Deployment cms has not finished its rollout"
kubectl get deploy cms -n blog -o json | jq -e '.spec.replicas==3 and .status.readyReplicas==3' >/dev/null   && pass "3 replicas of cms are ready" || fail "Deployment cms must run 3 ready replicas"
