#!/bin/bash
pass() { echo "✅ $1"; exit 0; }
fail() { echo "❌ $1"; exit 1; }
for spec in "shop-svc shop 80" "api-svc api 8080"; do
  set -- $spec
  V=$(kubectl get svc $1 -n ingress-lab -o jsonpath='{.spec.type}|{.spec.selector.app}|{.spec.ports[0].port}|{.spec.ports[0].targetPort}' 2>/dev/null) || fail "Service $1 not found"
  [ "$V" = "ClusterIP|$2|$3|80" ] || fail "Service $1 incorrect: $V (expected ClusterIP|$2|$3|80)"
  N=$(kubectl get endpointslices -n ingress-lab -l kubernetes.io/service-name=$1 -o jsonpath='{range .items[*].endpoints[*]}{.addresses[0]}{"\n"}{end}' | grep -c .)
  [ "$N" -ge 1 ] || fail "Service $1 has no endpoints"
done
pass "Both Services correct"
