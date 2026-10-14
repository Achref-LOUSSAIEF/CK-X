#!/bin/bash
pass() { echo "✅ $1"; exit 0; }
fail() { echo "❌ $1"; exit 1; }
kubectl get pod multi -n default >/dev/null 2>&1 || fail "Pod multi not found in default"
kubectl wait --for=condition=Ready pod/multi -n default --timeout=30s >/dev/null 2>&1 \
  && pass "multi is Ready" || fail "multi is not Running/Ready"
