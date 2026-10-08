#!/bin/bash
pass() { echo "✅ $1"; exit 0; }
fail() { echo "❌ $1"; exit 1; }
L=$(kubectl get limitrange test-limits -n test -o json 2>/dev/null) || fail "LimitRange test-limits not found"
echo "$L" | jq -e '.spec.limits[] | select(.type=="Container") |
  .min.cpu=="100m" and .min.memory=="128Mi" and (.max.cpu=="1" or .max.cpu=="1000m") and .max.memory=="1Gi" and
  .defaultRequest.cpu=="100m" and .defaultRequest.memory=="128Mi" and .default.cpu=="500m" and .default.memory=="512Mi"' >/dev/null \
  && pass "LimitRange correct" || fail "LimitRange values incorrect"
