#!/bin/bash
pass() { echo "✅ $1"; exit 0; }
fail() { echo "❌ $1"; exit 1; }
V=$(kubectl get svc legacy-app -n legacy -o jsonpath='{.spec.type}|{.spec.selector.app}|{.spec.ports[0].port}|{.spec.ports[0].targetPort}|{.spec.ports[0].nodePort}' 2>/dev/null) || fail "Service legacy-app not found"
[ "$V" = "NodePort|legacy-app|8080|3000|30808" ] && pass "Service correct" || fail "Service incorrect: $V"
