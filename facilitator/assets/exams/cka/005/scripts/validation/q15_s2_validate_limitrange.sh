#!/bin/bash
pass() { echo "✅ $1"; exit 0; }
fail() { echo "❌ $1"; exit 1; }
L=$(kubectl get limitrange batch-jobs-limits -n batch-jobs -o json 2>/dev/null) || fail "LimitRange batch-jobs-limits not found"
echo "$L" | jq -e '.spec.limits[] | select(.type=="Container") |
  .min.cpu=="500m" and .min.memory=="256Mi" and (.max.cpu=="4" or .max.cpu=="4000m") and .max.memory=="8Gi" and
  (.default.cpu=="1" or .default.cpu=="1000m") and .default.memory=="1Gi" and .defaultRequest.cpu=="500m" and .defaultRequest.memory=="256Mi"' >/dev/null \
  && pass "LimitRange correct" || fail "LimitRange values incorrect"
