#!/bin/bash
pass() { echo "✅ $1"; exit 0; }
fail() { echo "❌ $1"; exit 1; }
D=$(kubectl get deploy web -n web -o json 2>/dev/null) || fail "Deployment web not found"
echo "$D" | jq -e '.spec.template.spec.containers[0].readinessProbe | (.httpGet.port==80 or .httpGet.port=="http" or .tcpSocket.port==80)' >/dev/null \
  && pass "Probe fixed" || fail "web must keep a readiness probe on port 80"
