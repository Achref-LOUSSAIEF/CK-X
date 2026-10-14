#!/bin/bash
pass() { echo "✅ $1"; exit 0; }
fail() { echo "❌ $1"; exit 1; }
P=$(kubectl get pod meta-reporter -n telemetry -o json 2>/dev/null) || fail "Pod meta-reporter not found"
C='.spec.containers[0]'
echo "$P" | jq -e "$C.resources.limits.memory==\"64Mi\"" >/dev/null || fail "Memory limit must be 64Mi"
f() { echo "$P" | jq -r --arg n "$1" "$C.env[]? | select(.name==\$n) | .valueFrom.fieldRef.fieldPath // empty"; }
[ "$(f POD_NAME)" = "metadata.name" ] || fail "POD_NAME must use fieldRef metadata.name"
[ "$(f POD_IP)" = "status.podIP" ] || fail "POD_IP must use fieldRef status.podIP"
[ "$(f NODE_NAME)" = "spec.nodeName" ] || fail "NODE_NAME must use fieldRef spec.nodeName"
M=$(echo "$P" | jq -c "$C.env[]? | select(.name==\"MEM_LIMIT_MI\") | .valueFrom.resourceFieldRef")
echo "$M" | jq -e '.resource=="limits.memory" and (.divisor=="1Mi")' >/dev/null && pass "Downward API configured" || fail "MEM_LIMIT_MI must use resourceFieldRef limits.memory with divisor 1Mi (got $M)"
