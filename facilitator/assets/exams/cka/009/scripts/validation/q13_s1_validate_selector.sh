#!/bin/bash
pass() { echo "✅ $1"; exit 0; }
fail() { echo "❌ $1"; exit 1; }
[ "$(kubectl get deploy orders -n shop -o jsonpath='{.spec.replicas}|{.spec.template.metadata.labels.app}' 2>/dev/null)" = "2|orders" ] || fail "The orders Deployment was changed"
[ "$(kubectl get svc orders-svc -n shop -o jsonpath='{.spec.selector.app}' 2>/dev/null)" = "orders" ] && pass "Selector fixed" || fail "orders-svc must select app=orders"
