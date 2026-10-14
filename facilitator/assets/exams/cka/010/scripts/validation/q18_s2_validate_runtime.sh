#!/bin/bash
pass() { echo "✅ $1"; exit 0; }
fail() { echo "❌ $1"; exit 1; }
kubectl wait --for=condition=Ready pod/log-pair -n logs --timeout=30s >/dev/null 2>&1 || fail "log-pair is not Ready"
sleep 6
kubectl logs log-pair -n logs -c reader 2>/dev/null | grep -qE '[0-9]{2}:[0-9]{2}:[0-9]{2}' && pass "reader prints the log" || fail "reader does not print the writer's log lines"
