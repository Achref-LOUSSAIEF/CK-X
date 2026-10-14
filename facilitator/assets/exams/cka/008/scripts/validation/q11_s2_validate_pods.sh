#!/bin/bash
pass() { echo "✅ $1"; exit 0; }
fail() { echo "❌ $1"; exit 1; }
kubectl rollout status deploy/edge-cache -n edge --timeout=40s >/dev/null 2>&1
N=$(kubectl get pods -n edge -l app=edge-cache -o json | jq '[.items[] | select(.metadata.deletionTimestamp==null) | select([.spec.tolerations[]? | select(.key=="node.kubernetes.io/unreachable" and .tolerationSeconds==30)] | length == 1)] | length')
[ "$N" -ge 2 ] && pass "Pods updated" || fail "Only $N edge-cache Pod(s) have the 30 s toleration"
