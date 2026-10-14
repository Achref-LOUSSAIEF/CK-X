#!/bin/bash
pass() { echo "✅ $1"; exit 0; }
fail() { echo "❌ $1"; exit 1; }
kubectl wait --for=condition=Ready pod/api-client pod/intruder -n db --timeout=30s >/dev/null 2>&1 || fail "Test Pods are not Ready"
kubectl rollout status deploy/db -n db --timeout=30s >/dev/null 2>&1
IP=$(kubectl get pod -n db -l app=db -o jsonpath='{.items[0].status.podIP}')
[ -n "$IP" ] || fail "No db Pod IP"
kubectl exec -n db api-client -- nc -z -w 3 "$IP" 6379 >/dev/null 2>&1 || fail "api-client cannot reach db on 6379"
kubectl exec -n db intruder -- nc -z -w 3 "$IP" 6379 >/dev/null 2>&1 && fail "intruder can still reach db on 6379"
pass "Traffic is filtered as required"
