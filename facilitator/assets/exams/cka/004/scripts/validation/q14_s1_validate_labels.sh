#!/bin/bash
pass() { echo "✅ $1"; exit 0; }
fail() { echo "❌ $1"; exit 1; }
E=$(kubectl get ns restricted -o jsonpath='{.metadata.labels.pod-security\.kubernetes\.io/enforce}' 2>/dev/null) || fail "Namespace restricted not found"
A=$(kubectl get ns restricted -o jsonpath='{.metadata.labels.pod-security\.kubernetes\.io/audit}')
[ "$E" = "restricted" ] && [ "$A" = "baseline" ] && pass "Labels correct" || fail "enforce=$E audit=$A"
