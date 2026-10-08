#!/bin/bash
pass() { echo "✅ $1"; exit 0; }
fail() { echo "❌ $1"; exit 1; }
NS=$(kubectl get deploy batch-processor -n trbl-sched -o jsonpath='{.spec.template.spec.nodeSelector.disktype}' 2>/dev/null) || fail "Deployment not found"
[ -z "$NS" ] && pass "nodeSelector disktype removed" || fail "nodeSelector disktype=$NS still present"
