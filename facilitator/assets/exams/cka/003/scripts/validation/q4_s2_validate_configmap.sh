#!/bin/bash
pass() { echo "✅ $1"; exit 0; }
fail() { echo "❌ $1"; exit 1; }
Q=$(kubectl get cm order-config -n trbl-config -o jsonpath='{.data.queue_name}' 2>/dev/null)
L=$(kubectl get cm order-config -n trbl-config -o jsonpath='{.data.log_level}' 2>/dev/null)
[ "$Q" = "orders" ] || fail "ConfigMap key queue_name is '$Q', expected 'orders'"
[ "$L" = "info" ] && pass "ConfigMap correct" || fail "Existing key log_level was removed or changed"
