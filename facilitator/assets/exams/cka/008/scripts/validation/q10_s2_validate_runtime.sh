#!/bin/bash
pass() { echo "✅ $1"; exit 0; }
fail() { echo "❌ $1"; exit 1; }
kubectl wait --for=condition=Ready pod/hardened -n secure --timeout=30s >/dev/null 2>&1 || fail "hardened is not Ready"
kubectl exec hardened -n secure -- touch /test 2>/dev/null && fail "The root filesystem is writable"
kubectl exec hardened -n secure -- sh -c 'test -s /work/log' 2>/dev/null || fail "/work/log is not being written"
[ "$(kubectl exec hardened -n secure -- id -u 2>/dev/null)" = "1000" ] && pass "Pod hardened works" || fail "The container does not run as UID 1000"
