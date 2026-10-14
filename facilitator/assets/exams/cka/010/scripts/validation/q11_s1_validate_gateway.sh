#!/bin/bash
pass() { echo "✅ $1"; exit 0; }
fail() { echo "❌ $1"; exit 1; }
G=$(kubectl get gateway main-gw -n media -o json 2>/dev/null) || fail "Gateway main-gw not found"
echo "$G" | jq -e '.spec.gatewayClassName=="nginx-gc" and ([.spec.listeners[] | select(.name=="http" and .protocol=="HTTP" and .port==80)] | length == 1)' >/dev/null \
  && pass "Gateway correct" || fail "main-gw must use class nginx-gc with a listener http, HTTP, port 80"
