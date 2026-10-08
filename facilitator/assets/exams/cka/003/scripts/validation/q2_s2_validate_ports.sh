#!/bin/bash
pass() { echo "✅ $1"; exit 0; }
fail() { echo "❌ $1"; exit 1; }
PORT=$(kubectl get svc web-svc -n trbl-svc -o jsonpath='{.spec.ports[0].port}')
TP=$(kubectl get svc web-svc -n trbl-svc -o jsonpath='{.spec.ports[0].targetPort}')
[ "$PORT" = "80" ] || fail "Service port is $PORT, expected 80"
[ "$TP" = "80" ] && pass "port 80 -> targetPort 80" || fail "targetPort is $TP, expected 80"
