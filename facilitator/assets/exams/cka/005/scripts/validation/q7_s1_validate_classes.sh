#!/bin/bash
pass() { echo "✅ $1"; exit 0; }
fail() { echo "❌ $1"; exit 1; }
C=$(kubectl get priorityclass critical -o jsonpath='{.value}|{.globalDefault}' 2>/dev/null) || fail "PriorityClass critical not found"
S=$(kubectl get priorityclass standard -o jsonpath='{.value}|{.globalDefault}' 2>/dev/null) || fail "PriorityClass standard not found"
[ "${C%%|*}" = "1000" ] && [ "${S%%|*}" = "100" ] || fail "Values incorrect: critical=$C standard=$S"
[ "${C#*|}" != "true" ] && [ "${S#*|}" != "true" ] && pass "PriorityClasses correct" || fail "Neither class may be globalDefault"
