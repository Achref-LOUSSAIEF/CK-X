#!/bin/bash
pass() { echo "✅ $1"; exit 0; }
fail() { echo "❌ $1"; exit 1; }
D=$(kubectl get deploy shop-v2 -n shop -o json 2>/dev/null) || fail "Deployment shop-v2 not found"
echo "$D" | jq -e '.spec.replicas==1 and .spec.template.spec.containers[0].image=="nginx:1.27" and .spec.template.metadata.labels.app=="shop" and .spec.template.metadata.labels.version=="v2"' >/dev/null \
  && pass "shop-v2 correct" || fail "shop-v2 must have 1 replica of nginx:1.27 with labels app=shop,version=v2"
