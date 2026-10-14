#!/bin/bash
pass() { echo "✅ $1"; exit 0; }
fail() { echo "❌ $1"; exit 1; }
V=$(kubectl get svc catalog-np -n catalog -o jsonpath='{.spec.type}|{.spec.selector.app}|{.spec.ports[0].port}|{.spec.ports[0].targetPort}|{.spec.ports[0].nodePort}' 2>/dev/null) || fail "Service catalog-np not found"
[ "$V" = "NodePort|catalog|80|http|30081" ] || fail "catalog-np incorrect: $V"
kubectl rollout status deploy/catalog -n catalog --timeout=30s >/dev/null 2>&1
N=$(kubectl get endpointslices -n catalog -l kubernetes.io/service-name=catalog-np -o jsonpath='{range .items[*].endpoints[*]}{.addresses[0]}{"\n"}{end}' | grep -c .)
[ "$N" -ge 2 ] && pass "catalog-np correct with $N endpoints" || fail "catalog-np has $N endpoints"
