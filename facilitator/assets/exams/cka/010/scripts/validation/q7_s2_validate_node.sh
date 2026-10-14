#!/bin/bash
pass() { echo "✅ $1"; exit 0; }
fail() { echo "❌ $1"; exit 1; }
kubectl wait --for=condition=Ready pod/east-pod -n default --timeout=30s >/dev/null 2>&1 || fail "east-pod is not Ready"
N=$(kubectl get pod east-pod -n default -o jsonpath='{.spec.nodeName}')
[ "$(kubectl get node "$N" -o jsonpath='{.metadata.labels.zone}')" = "east" ] && pass "on $N" || fail "east-pod runs on $N, not a zone=east node"
