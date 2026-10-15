#!/bin/bash
pass() { echo "✅ $1"; exit 0; }
fail() { echo "❌ $1"; exit 1; }
F=/tmp/exam/q2/schedulable-nodes.txt
[ -f "$F" ] || fail "$F not found"
EXP=$(kubectl get nodes -o json | jq '[.items[] | select(any(.status.conditions[]; .type=="Ready" and .status=="True")) | select(([.spec.taints[]? | select(.effect=="NoSchedule")] | length) == 0)] | length')
GOT=$(tr -d '[:space:]' < "$F")
[ "$GOT" = "$EXP" ] && pass "$EXP nodes" || fail "$F does not contain the number of Ready nodes without a NoSchedule taint"
