#!/bin/bash
pass() { echo "✅ $1"; exit 0; }
fail() { echo "❌ $1"; exit 1; }
ON=$(kubectl get pods -n maintenance -l app=web-tier --field-selector spec.nodeName=k3d-cluster-agent-1 --no-headers 2>/dev/null | grep -c .)
[ "$ON" -eq 0 ] || fail "$ON web-tier Pod(s) still on k3d-cluster-agent-1"
R=$(kubectl get deploy web-tier -n maintenance -o jsonpath='{.status.readyReplicas}')
[ "${R:-0}" -eq 3 ] && pass "3/3 Ready elsewhere" || fail "Ready replicas: ${R:-0}/3"
