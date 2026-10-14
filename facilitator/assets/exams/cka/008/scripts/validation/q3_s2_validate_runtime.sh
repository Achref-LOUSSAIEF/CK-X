#!/bin/bash
pass() { echo "✅ $1"; exit 0; }
fail() { echo "❌ $1"; exit 1; }
kubectl wait --for=condition=Ready pod/meta-reporter -n telemetry --timeout=30s >/dev/null 2>&1 || fail "meta-reporter is not Ready"
E=$(kubectl exec meta-reporter -n telemetry -- env 2>/dev/null)
N=$(kubectl get pod meta-reporter -n telemetry -o jsonpath='{.spec.nodeName}')
echo "$E" | grep -qx "POD_NAME=meta-reporter" && echo "$E" | grep -qx "NODE_NAME=$N" && echo "$E" | grep -qx "MEM_LIMIT_MI=64" \
  && pass "Values visible in the Pod" || fail "The environment of meta-reporter does not contain the expected values"
