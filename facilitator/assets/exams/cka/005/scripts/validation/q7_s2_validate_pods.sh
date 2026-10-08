#!/bin/bash
pass() { echo "✅ $1"; exit 0; }
fail() { echo "❌ $1"; exit 1; }
for p in critical-pod-1:critical:1000 critical-pod-2:critical:1000 standard-pod:standard:100; do
  IFS=: read -r n c v <<< "$p"
  V=$(kubectl get pod "$n" -n priority-lab -o jsonpath='{.spec.priorityClassName}|{.spec.priority}|{.status.phase}' 2>/dev/null) || fail "Pod $n not found"
  [ "$V" = "$c|$v|Running" ] || fail "Pod $n incorrect: $V"
done
pass "All Pods correct"
