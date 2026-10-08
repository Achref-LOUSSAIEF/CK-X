#!/bin/bash
pass() { echo "✅ $1"; exit 0; }
fail() { echo "❌ $1"; exit 1; }
S=$(kubectl get deploy report-generator -n sched-debug -o jsonpath='{.spec.template.spec.schedulerName}' 2>/dev/null) || fail "Deployment not found"
[ -z "$S" ] || [ "$S" = "default-scheduler" ] && pass "schedulerName: ${S:-default}" || fail "schedulerName is still '$S'"
