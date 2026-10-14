#!/bin/bash
pass() { echo "✅ $1"; exit 0; }
fail() { echo "❌ $1"; exit 1; }
kubectl wait --for=condition=Ready pod/restricted pod/sink -n dev --timeout=30s >/dev/null 2>&1 || fail "Test Pods are not Ready"
kubectl rollout status deploy/api -n dev --timeout=30s >/dev/null 2>&1
API=$(kubectl get pod -n dev -l app=api -o jsonpath='{.items[0].status.podIP}')
SINK=$(kubectl get pod sink -n dev -o jsonpath='{.status.podIP}')
kubectl exec -n dev restricted -- nc -z -w 3 "$API" 80 >/dev/null 2>&1 || fail "restricted cannot reach the api Pods on port 80"
kubectl exec -n dev restricted -- nc -z -w 3 "$SINK" 80 >/dev/null 2>&1 && fail "restricted can still reach sink"
pass "Egress filtered as required"
