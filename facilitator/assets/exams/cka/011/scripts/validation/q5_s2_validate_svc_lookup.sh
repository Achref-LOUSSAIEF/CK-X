#!/bin/bash
pass() { echo "✅ $1"; exit 0; }
fail() { echo "❌ $1"; exit 1; }
F=/tmp/exam/q5/nginx-random.svc
[ -f "$F" ] || fail "$F not found"
IP=$(kubectl get svc nginx-random -n lookup -o jsonpath='{.spec.clusterIP}' 2>/dev/null)
[ -n "$IP" ] || fail "Service nginx-random not found"
grep -q 'nginx-random' "$F" && grep -Fq "$IP" "$F" && pass "Service lookup saved" || fail "$F does not hold a lookup of the Service (name and ClusterIP $IP)"
