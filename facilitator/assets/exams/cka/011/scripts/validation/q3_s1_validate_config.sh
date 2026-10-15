#!/bin/bash
pass() { echo "✅ $1"; exit 0; }
fail() { echo "❌ $1"; exit 1; }
CF=$(kubectl get configmap coredns -n kube-system -o jsonpath='{.data.Corefile}')
echo "$CF" | grep -q '192\.0\.2\.53' && fail "CoreDNS still forwards to 192.0.2.53"
echo "$CF" | grep -Eq '^[[:space:]]*forward \. /etc/resolv\.conf' || fail "CoreDNS does not forward to the node's resolvers (forward . /etc/resolv.conf)"
echo "$CF" | grep -Eq 'kubernetes cluster\.local' || fail "The kubernetes plugin for cluster.local is missing"
kubectl rollout status deployment coredns -n kube-system --timeout=30s >/dev/null 2>&1 || fail "CoreDNS is not available"
pass "CoreDNS forwards external names again"
