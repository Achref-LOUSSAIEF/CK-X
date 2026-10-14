#!/bin/bash
pass() { echo "✅ $1"; exit 0; }
fail() { echo "❌ $1"; exit 1; }
C=$(kubectl get deploy report-gen -n reporting -o jsonpath='{.spec.template.spec.containers[0].command[*]} {.spec.template.spec.containers[0].args[*]}' 2>/dev/null) || fail "Deployment report-gen not found"
echo "$C" | grep -q "sleeep" && fail "The command still contains the typo"
echo "$C" | grep -q "sleep 3600" && echo "$C" | grep -q "starting report generator" || fail "Command must print 'starting report generator' and run 'sleep 3600'"
kubectl rollout status deploy/report-gen -n reporting --timeout=30s >/dev/null 2>&1
A=$(kubectl get deploy report-gen -n reporting -o jsonpath='{.status.availableReplicas}')
[ "${A:-0}" -ge 1 ] && pass "report-gen running" || fail "report-gen is not available"
