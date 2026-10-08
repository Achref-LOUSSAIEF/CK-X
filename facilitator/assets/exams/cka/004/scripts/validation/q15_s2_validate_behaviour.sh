#!/bin/bash
pass() { echo "✅ $1"; exit 0; }
fail() { echo "❌ $1"; exit 1; }
kubectl wait --for=condition=Ready pod/app-with-logger -n default --timeout=15s >/dev/null 2>&1 || fail "Pod is not Ready"
kubectl exec app-with-logger -n default -c nginx -- curl -s http://localhost/ >/dev/null 2>&1 || fail "nginx does not answer"
sleep 2
kubectl logs app-with-logger -n default -c logger 2>/dev/null | grep -q 'GET / ' && pass "logger shows access log" || fail "logger does not show nginx requests"
