#!/bin/bash
pass() { echo "✅ $1"; exit 0; }
fail() { echo "❌ $1"; exit 1; }
NODES=$(kubectl get nodes --no-headers | grep -c .)
DES=$(kubectl get ds node-agent -n ds-lab -o jsonpath='{.status.desiredNumberScheduled}')
RDY=$(kubectl get ds node-agent -n ds-lab -o jsonpath='{.status.numberReady}')
[ "${DES:-0}" -eq "$NODES" ] || fail "DaemonSet targets ${DES:-0} of $NODES nodes"
[ "${RDY:-0}" -eq "$NODES" ] && pass "node-agent Ready on all $NODES nodes" || fail "Ready on ${RDY:-0}/$NODES nodes"
