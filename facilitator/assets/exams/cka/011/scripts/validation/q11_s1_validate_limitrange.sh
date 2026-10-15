#!/bin/bash
pass() { echo "✅ $1"; exit 0; }
fail() { echo "❌ $1"; exit 1; }
L=$(kubectl get limitrange container-limits -n limits-lab -o json 2>/dev/null) || fail "LimitRange container-limits not found"
echo "$L" | jq -e '[.spec.limits[] | select(.type=="Container")][0] as $c |
  $c.defaultRequest.cpu=="100m" and $c.defaultRequest.memory=="50Mi" and
  $c.default.cpu=="200m" and $c.default.memory=="100Mi" and $c.max.memory=="500Mi"' >/dev/null   && pass "LimitRange values" || fail "container-limits must set defaultRequest 100m/50Mi, default 200m/100Mi and max memory 500Mi for Containers"
