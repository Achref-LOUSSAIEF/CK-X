#!/bin/bash
pass() { echo "✅ $1"; exit 0; }
fail() { echo "❌ $1"; exit 1; }
[ "$(kubectl get node k3d-cluster-agent-1 -o jsonpath='{.spec.unschedulable}')" = "true" ] || fail "k3d-cluster-agent-1 is not cordoned"
N=$(kubectl get pods -A --field-selector spec.nodeName=k3d-cluster-agent-1 -o json | jq '[.items[] | select(.metadata.deletionTimestamp==null) | select((.metadata.ownerReferences // []) | map(.kind) | index("DaemonSet") | not)] | length')
[ "$N" -eq 0 ] && pass "Node drained" || fail "$N workload Pod(s) still on k3d-cluster-agent-1"
