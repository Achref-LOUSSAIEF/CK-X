#!/bin/bash
pass() { echo "✅ $1"; exit 0; }
fail() { echo "❌ $1"; exit 1; }
CFG=$(kubectl get configmap coredns coredns-custom -n kube-system -o json 2>/dev/null | jq -r '.items[].data // {} | .[]')
echo "$CFG" | grep -q 'myapp\.internal' && echo "$CFG" | grep -q '10\.10\.10\.10'   && pass "CoreDNS configuration maps myapp.internal" || fail "No CoreDNS configuration maps myapp.internal to 10.10.10.10"
