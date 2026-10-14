#!/bin/bash
pass() { echo "✅ $1"; exit 0; }
fail() { echo "❌ $1"; exit 1; }
J=$(kubectl get job batch-import -n batch -o json 2>/dev/null) || fail "Job batch-import not found"
echo "$J" | jq -e '.spec.completions==6 and .spec.parallelism==2 and .spec.backoffLimit==3 and .spec.ttlSecondsAfterFinished==10800' >/dev/null || fail "Job spec incorrect: $(echo "$J" | jq -c '{completions:.spec.completions,parallelism:.spec.parallelism,backoffLimit:.spec.backoffLimit,ttl:.spec.ttlSecondsAfterFinished}')"
echo "$J" | jq -e '.spec.template.spec.containers[0].image=="busybox:1.36"' >/dev/null && pass "Job spec correct" || fail "Image must be busybox:1.36"
