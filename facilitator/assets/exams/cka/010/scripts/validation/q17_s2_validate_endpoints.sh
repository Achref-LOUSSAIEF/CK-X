#!/bin/bash
pass() { echo "✅ $1"; exit 0; }
fail() { echo "❌ $1"; exit 1; }
kubectl rollout status deploy/exporter -n metrics --timeout=30s >/dev/null 2>&1
P=$(kubectl get endpointslices -n metrics -l kubernetes.io/service-name=exporter -o json | jq -c '[.items[] | select([.endpoints[]? | select(.conditions.ready)] | length > 0) | .ports[].port] | sort')
[ "$P" = "[8080,9100]" ] && pass "Endpoints on 8080 and 9100" || fail "exporter endpoint ports: $P"
