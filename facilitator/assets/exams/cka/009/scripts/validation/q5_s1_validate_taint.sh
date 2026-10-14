#!/bin/bash
pass() { echo "✅ $1"; exit 0; }
fail() { echo "❌ $1"; exit 1; }
T=$(kubectl get node k3d-cluster-agent-1 -o json | jq -c '[.spec.taints[]? | select(.key=="env" and .value=="prod" and .effect=="NoSchedule")] | length')
[ "$T" = "1" ] && pass "Taint set" || fail "k3d-cluster-agent-1 has no taint env=prod:NoSchedule"
