#!/bin/bash
pass() { echo "✅ $1"; exit 0; }
fail() { echo "❌ $1"; exit 1; }
kubectl get ns restricted >/dev/null 2>&1 || fail "Namespace restricted not found"
OK='{"apiVersion":"v1","kind":"Pod","metadata":{"name":"ok-test","namespace":"restricted"},"spec":{"securityContext":{"runAsNonRoot":true,"runAsUser":1000,"seccompProfile":{"type":"RuntimeDefault"}},"containers":[{"name":"c","image":"busybox:1.36","securityContext":{"allowPrivilegeEscalation":false,"capabilities":{"drop":["ALL"]}}}]}}'
echo "$OK" | kubectl apply --dry-run=server -f - >/dev/null 2>&1 || fail "Even a compliant Pod is rejected (check the namespace)"
POD='{"apiVersion":"v1","kind":"Pod","metadata":{"name":"priv-test","namespace":"restricted"},"spec":{"containers":[{"name":"c","image":"busybox:1.36","securityContext":{"privileged":true}}]}}'
echo "$POD" | kubectl apply --dry-run=server -f - >/dev/null 2>&1 && fail "Privileged Pod was accepted"
pass "Privileged Pod denied"
