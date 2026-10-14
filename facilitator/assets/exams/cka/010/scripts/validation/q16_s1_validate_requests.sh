#!/bin/bash
pass() { echo "✅ $1"; exit 0; }
fail() { echo "❌ $1"; exit 1; }
R=$(kubectl get deploy analytics -n analytics -o json 2>/dev/null) || fail "Deployment analytics not found"
echo "$R" | jq -e '.spec.template.spec.containers[0].resources.requests | (.cpu=="100m" or .cpu=="0.1") and .memory=="128Mi"' >/dev/null \
  && pass "Requests fixed" || fail "analytics must request cpu 100m and memory 128Mi"
