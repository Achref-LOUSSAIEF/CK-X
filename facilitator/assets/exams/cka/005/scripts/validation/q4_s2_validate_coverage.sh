#!/bin/bash
pass() { echo "✅ $1"; exit 0; }
fail() { echo "❌ $1"; exit 1; }
N=$(kubectl get nodes --no-headers | grep -c .)
D=$(kubectl get ds monitoring-agent -n monitoring -o jsonpath='{.status.desiredNumberScheduled}')
R=$(kubectl get ds monitoring-agent -n monitoring -o jsonpath='{.status.numberReady}')
ON=$(kubectl get pods -n monitoring -l app=monitoring-agent --field-selector spec.nodeName=k3d-cluster-server-0 --no-headers 2>/dev/null | grep -c .)
[ "${D:-0}" -eq "$N" ] && [ "${R:-0}" -eq "$N" ] && [ "$ON" -ge 1 ] && pass "Running on all $N nodes" || fail "Ready on ${R:-0}/$N nodes (control plane: $ON)"
