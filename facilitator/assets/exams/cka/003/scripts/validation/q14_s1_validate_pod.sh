#!/bin/bash
pass() { echo "✅ $1"; exit 0; }
fail() { echo "❌ $1"; exit 1; }
N=$(kubectl get pod web-logger -n sidecar-lab -o jsonpath='{.spec.nodeName}' 2>/dev/null) || fail "Pod web-logger not found"
[ "$N" = "k3d-cluster-server-0" ] || fail "Pod runs on '$N', expected k3d-cluster-server-0"
kubectl wait --for=condition=Ready pod/web-logger -n sidecar-lab --timeout=15s >/dev/null 2>&1 && pass "Pod Ready on $N" || fail "Pod is not Ready"
