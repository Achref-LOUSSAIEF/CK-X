#!/bin/bash
pass() { echo "✅ $1"; exit 0; }
fail() { echo "❌ $1"; exit 1; }
Q=$(kubectl get resourcequota team-quota -n team-a -o json 2>/dev/null) || fail "ResourceQuota team-quota not found"
echo "$Q" | jq -e '.spec.hard | (.pods=="10") and ((.["requests.cpu"] // .cpu)=="2") and ((.["requests.memory"] // .memory)=="2Gi")' >/dev/null \
  && pass "Quota correct" || fail "team-quota must allow pods 10, requests.cpu 2, requests.memory 2Gi"
