#!/bin/bash
pass() { echo "✅ $1"; exit 0; }
fail() { echo "❌ $1"; exit 1; }
kubectl get pod report -n reports >/dev/null 2>&1 || fail "Pod report not found in reports"
kubectl wait --for=condition=Ready pod/report -n reports --timeout=30s >/dev/null 2>&1 \
  && pass "report is Ready" || fail "report is not Running/Ready"
