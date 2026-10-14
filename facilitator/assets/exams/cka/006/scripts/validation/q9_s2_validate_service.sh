#!/bin/bash
pass() { echo "✅ $1"; exit 0; }
fail() { echo "❌ $1"; exit 1; }
V=$(kubectl get svc store-api -n store -o jsonpath='{.spec.ports[0].port}|{.spec.ports[0].targetPort}' 2>/dev/null) || fail "Service store-api not found"
[ "$V" = "8080|http" ] || fail "Service store-api was modified ($V)"
N=$(kubectl get endpointslices -n store -l kubernetes.io/service-name=store-api -o jsonpath='{range .items[*].endpoints[*]}{.addresses[0]}{"\n"}{end}' | grep -c .)
[ "$N" -ge 1 ] && pass "store-api has endpoints" || fail "store-api has no endpoints"
