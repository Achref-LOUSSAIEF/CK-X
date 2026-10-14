#!/bin/bash
pass() { echo "✅ $1"; exit 0; }
fail() { echo "❌ $1"; exit 1; }
V=$(kubectl get priorityclass urgent -o jsonpath='{.value}|{.globalDefault}' 2>/dev/null) || fail "PriorityClass urgent not found"
[ "${V%%|*}" = "499999" ] || fail "urgent has value ${V%%|*}, expected one less than the highest user-defined class"
[ "${V#*|}" != "true" ] && pass "urgent = 499999" || fail "urgent must not be globalDefault"
