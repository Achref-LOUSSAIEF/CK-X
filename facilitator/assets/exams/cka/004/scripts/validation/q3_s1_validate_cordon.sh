#!/bin/bash
pass() { echo "✅ $1"; exit 0; }
fail() { echo "❌ $1"; exit 1; }
U=$(kubectl get node k3d-cluster-agent-1 -o jsonpath='{.spec.unschedulable}' 2>/dev/null) || fail "Node k3d-cluster-agent-1 not found"
[ "$U" = "true" ] && pass "Node cordoned" || fail "Node is still schedulable"
