#!/bin/bash
pass() { echo "✅ $1"; exit 0; }
fail() { echo "❌ $1"; exit 1; }
ON=$(kubectl get pods -n maintenance -l app=maint-web --field-selector spec.nodeName=k3d-cluster-agent-0 --no-headers 2>/dev/null | grep -c .)
[ "$ON" -eq 0 ] || fail "$ON maint-web Pod(s) still on k3d-cluster-agent-0"
R=$(kubectl get deploy maint-web -n maintenance -o jsonpath='{.status.readyReplicas}')
[ "${R:-0}" -eq 3 ] && pass "3/3 Ready on other nodes" || fail "Ready replicas: ${R:-0}/3"
