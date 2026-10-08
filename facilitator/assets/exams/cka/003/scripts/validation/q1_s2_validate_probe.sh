#!/bin/bash
pass() { echo "✅ $1"; exit 0; }
fail() { echo "❌ $1"; exit 1; }
PORT=$(kubectl get deploy payment-api -n trbl-deploy -o jsonpath='{.spec.template.spec.containers[0].readinessProbe.httpGet.port}{.spec.template.spec.containers[0].readinessProbe.tcpSocket.port}')
[ -z "$PORT" ] && fail "Readiness probe was removed"
if [ "$PORT" = "80" ]; then pass "Readiness probe checks port 80"; fi
# named port that resolves to 80 is also fine
NAMED=$(kubectl get deploy payment-api -n trbl-deploy -o jsonpath="{.spec.template.spec.containers[0].ports[?(@.name=='$PORT')].containerPort}")
[ "$NAMED" = "80" ] && pass "Readiness probe checks named port $PORT (80)" || fail "Readiness probe checks port '$PORT', expected 80"
