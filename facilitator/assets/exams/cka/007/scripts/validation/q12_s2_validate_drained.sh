#!/bin/bash
pass() { echo "✅ $1"; exit 0; }
fail() { echo "❌ $1"; exit 1; }
[ "$(kubectl get node k3d-cluster-agent-0 -o jsonpath='{.spec.unschedulable}' 2>/dev/null)" = "true" ] || fail "k3d-cluster-agent-0 is not cordoned"
N=$(kubectl get pods -A --field-selector spec.nodeName=k3d-cluster-agent-0 -o json | jq '[.items[] | select((.metadata.ownerReferences // []) | map(.kind) | index("DaemonSet") | not) | select(.metadata.namespace=="ledger")] | length')
[ "$N" -eq 0 ] || fail "$N ledger Pod(s) still on k3d-cluster-agent-0"
R=$(kubectl get deploy ledger -n ledger -o jsonpath='{.status.readyReplicas}')
[ "${R:-0}" -eq 2 ] && pass "Drained, ledger 2/2 Ready" || fail "ledger Ready replicas: ${R:-0}/2"
