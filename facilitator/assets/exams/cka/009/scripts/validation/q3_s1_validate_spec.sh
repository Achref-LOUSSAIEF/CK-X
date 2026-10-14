#!/bin/bash
pass() { echo "✅ $1"; exit 0; }
fail() { echo "❌ $1"; exit 1; }
P=$(kubectl get pod multi -n default -o json 2>/dev/null) || fail "Pod multi not found"
echo "$P" | jq -e '(.spec.containers | length == 2)
  and ([.spec.containers[] | select(.name=="web" and .image=="nginx:1.27")] | length == 1)
  and ([.spec.containers[] | select(.name=="sidecar" and .image=="busybox:1.36" and ((.command // []) + (.args // []) | join(" ") | test("sleep 3600")))] | length == 1)' >/dev/null \
  && pass "multi correct" || fail "multi must have exactly the containers web (nginx:1.27) and sidecar (busybox:1.36, sleep 3600)"
