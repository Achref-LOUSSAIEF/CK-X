#!/bin/bash
pass() { echo "✅ $1"; exit 0; }
fail() { echo "❌ $1"; exit 1; }
kubectl wait --for=condition=Ready pod/ssd-pod -n default --timeout=30s >/dev/null 2>&1 || fail "ssd-pod is not Ready"
N=$(kubectl get pod ssd-pod -n default -o jsonpath='{.spec.nodeName}')
[ "$(kubectl get node "$N" -o jsonpath='{.metadata.labels.disk}')" = "ssd" ] && pass "on $N" || fail "ssd-pod runs on $N, which is not labeled disk=ssd"
