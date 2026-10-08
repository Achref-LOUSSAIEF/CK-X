#!/bin/bash
pass() { echo "✅ $1"; exit 0; }
fail() { echo "❌ $1"; exit 1; }
kubectl get ns privileged-apps >/dev/null 2>&1 || fail "Namespace privileged-apps not created yet"
E=$(kubectl get ns restricted-apps -o jsonpath='{.metadata.labels.pod-security\.kubernetes\.io/enforce}' 2>/dev/null)
[ "$E" = "restricted" ] || fail "restricted-apps enforce level changed to '$E'"
POD='{"apiVersion":"v1","kind":"Pod","metadata":{"name":"root-test","namespace":"restricted-apps"},"spec":{"securityContext":{"runAsUser":0},"containers":[{"name":"c","image":"nginx:1.25"}]}}'
echo "$POD" | kubectl apply --dry-run=server -f - >/dev/null 2>&1 && fail "restricted-apps accepts root Pods"
pass "restricted-apps unchanged"
