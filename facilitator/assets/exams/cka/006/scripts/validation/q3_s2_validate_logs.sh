#!/bin/bash
pass() { echo "✅ $1"; exit 0; }
fail() { echo "❌ $1"; exit 1; }
kubectl rollout status deploy/invoice-api -n billing --timeout=30s >/dev/null 2>&1 || fail "invoice-api rollout not complete"
sleep 3
kubectl logs deploy/invoice-api -n billing -c log-shipper --tail=20 2>/dev/null | grep -q "status=issued" \
  && pass "log-shipper shows the log" || fail "log-shipper does not show the application log"
