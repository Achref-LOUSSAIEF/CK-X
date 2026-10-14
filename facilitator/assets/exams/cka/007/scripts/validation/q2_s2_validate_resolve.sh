#!/bin/bash
pass() { echo "✅ $1"; exit 0; }
fail() { echo "❌ $1"; exit 1; }
kubectl exec -n sales sales-client -- nslookup kubernetes.default.svc.cluster.local >/dev/null 2>&1 \
  && pass "DNS works" || fail "sales-client still cannot resolve names"
