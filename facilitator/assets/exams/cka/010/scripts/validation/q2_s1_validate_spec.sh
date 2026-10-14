#!/bin/bash
pass() { echo "✅ $1"; exit 0; }
fail() { echo "❌ $1"; exit 1; }
J=$(kubectl get job pi -n dev -o json 2>/dev/null) || fail "Job pi not found"
echo "$J" | jq -e '.spec.completions==2 and .spec.parallelism==2 and .spec.backoffLimit==4 and .spec.template.spec.containers[0].image=="busybox:1.36"' >/dev/null \
  && pass "Job spec correct" || fail "pi needs completions 2, parallelism 2, backoffLimit 4, image busybox:1.36"
