#!/bin/bash
pass() { echo "✅ $1"; exit 0; }
fail() { echo "❌ $1"; exit 1; }
OUT=$(kubectl exec web-logger -n sidecar-lab -c nginx -- curl -s http://localhost/ 2>/dev/null)
echo "$OUT" | grep -q "Hello CKA" || fail "nginx does not serve 'Hello CKA'"
sleep 2
kubectl logs web-logger -n sidecar-lab -c log-tailer 2>/dev/null | grep -q 'GET / ' && pass "Sidecar shows access log" || fail "log-tailer logs do not show the request"
