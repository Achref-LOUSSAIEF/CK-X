#!/bin/bash
pass() { echo "✅ $1"; exit 0; }
fail() { echo "❌ $1"; exit 1; }
kubectl rollout status deploy/resolver -n trbl-dns --timeout=20s >/dev/null 2>&1 || fail "Deployment resolver not rolled out"
kubectl exec deploy/resolver -n trbl-dns -- nslookup kubernetes.default.svc.cluster.local >/dev/null 2>&1 \
  && pass "DNS resolution works" || fail "nslookup still fails"
