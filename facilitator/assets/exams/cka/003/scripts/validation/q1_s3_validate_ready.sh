#!/bin/bash
pass() { echo "✅ $1"; exit 0; }
fail() { echo "❌ $1"; exit 1; }
kubectl rollout status deploy/payment-api -n trbl-deploy --timeout=20s >/dev/null 2>&1
READY=$(kubectl get deploy payment-api -n trbl-deploy -o jsonpath='{.status.readyReplicas}')
UPD=$(kubectl get deploy payment-api -n trbl-deploy -o jsonpath='{.status.updatedReplicas}')
[ "${READY:-0}" -eq 2 ] && [ "${UPD:-0}" -eq 2 ] && pass "2/2 replicas Ready" || fail "Ready replicas: ${READY:-0}/2"
