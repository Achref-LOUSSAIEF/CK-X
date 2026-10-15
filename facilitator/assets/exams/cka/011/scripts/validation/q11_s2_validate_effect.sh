#!/bin/bash
pass() { echo "✅ $1"; exit 0; }
fail() { echo "❌ $1"; exit 1; }
P=$(kubectl run lr-check -n limits-lab --image=nginx:1.27 --dry-run=server -o json 2>/dev/null) || fail "A Pod without resources is rejected"
echo "$P" | jq -e '.spec.containers[0].resources | .requests.cpu=="100m" and .requests.memory=="50Mi" and .limits.cpu=="200m" and .limits.memory=="100Mi"' >/dev/null || fail "Pods without resources do not get the defaults"
kubectl run lr-big -n limits-lab --image=nginx:1.27 --dry-run=server --overrides='{"spec":{"containers":[{"name":"lr-big","image":"nginx:1.27","resources":{"limits":{"memory":"600Mi"}}}]}}' >/dev/null 2>&1   && fail "A container with a 600Mi memory limit is still accepted"
pass "Defaults applied and the 500Mi maximum enforced"
