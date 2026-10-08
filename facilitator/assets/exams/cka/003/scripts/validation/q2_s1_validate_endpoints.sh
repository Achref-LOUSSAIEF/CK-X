#!/bin/bash
pass() { echo "✅ $1"; exit 0; }
fail() { echo "❌ $1"; exit 1; }
LBL=$(kubectl get deploy web -n trbl-svc -o jsonpath='{.spec.template.metadata.labels.app}' 2>/dev/null)
[ "$LBL" = "web-frontend" ] || fail "Deployment web was modified (pod label app=$LBL)"
SEL=$(kubectl get svc web-svc -n trbl-svc -o jsonpath='{.spec.selector.app}' 2>/dev/null) || fail "Service web-svc not found"
[ "$SEL" = "web-frontend" ] || fail "Service selector app=$SEL does not match the Pods (app=web-frontend)"
N=$(kubectl get endpointslices -n trbl-svc -l kubernetes.io/service-name=web-svc -o jsonpath='{range .items[*].endpoints[*]}{.addresses[0]}{"\n"}{end}' | grep -c .)
[ "$N" -ge 2 ] && pass "Service has $N endpoints" || fail "Service has $N endpoints, expected 2"
