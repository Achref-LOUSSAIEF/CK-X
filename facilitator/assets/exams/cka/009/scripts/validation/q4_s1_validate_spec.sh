#!/bin/bash
pass() { echo "✅ $1"; exit 0; }
fail() { echo "❌ $1"; exit 1; }
P=$(kubectl get pod ssd-pod -n default -o json 2>/dev/null) || fail "Pod ssd-pod not found"
echo "$P" | jq -e '.spec.nodeSelector.disk=="ssd" and .spec.containers[0].image=="nginx:1.27"' >/dev/null \
  && pass "nodeSelector set" || fail "ssd-pod needs nodeSelector disk=ssd and image nginx:1.27"
