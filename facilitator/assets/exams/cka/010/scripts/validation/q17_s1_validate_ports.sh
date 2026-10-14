#!/bin/bash
pass() { echo "✅ $1"; exit 0; }
fail() { echo "❌ $1"; exit 1; }
S=$(kubectl get svc exporter -n metrics -o json 2>/dev/null) || fail "Service exporter not found"
echo "$S" | jq -e '.spec.selector.app=="exporter"' >/dev/null || fail "exporter must select app=exporter"
P=$(echo "$S" | jq -c '[.spec.ports[] | {name, port, targetPort}] | sort_by(.port)')
[ "$P" = '[{"name":"http","port":80,"targetPort":"http"},{"name":"metrics","port":9100,"targetPort":"metrics"}]' ] \
  && pass "Ports correct" || fail "Ports are $P"
