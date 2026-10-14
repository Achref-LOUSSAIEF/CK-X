#!/bin/bash
pass() { echo "✅ $1"; exit 0; }
fail() { echo "❌ $1"; exit 1; }
P=$(kubectl get netpol -n backend -o jsonpath='{.items[*].metadata.name}' | tr ' ' '\n' | grep -v '^default-deny-ingress$' | sort | tr '\n' ' ')
[ "$P" = "allow-frontend-ns " ] || fail "Policies in backend (besides default-deny): '${P:-none}'"
kubectl get netpol default-deny-ingress -n backend >/dev/null 2>&1 || fail "default-deny-ingress was deleted"
S=$(kubectl get netpol allow-frontend-ns -n backend -o json | jq -cS '.spec.ingress')
E=$(echo '[{"from":[{"namespaceSelector":{"matchLabels":{"kubernetes.io/metadata.name":"frontend"}},"podSelector":{"matchLabels":{"app":"frontend"}}}],"ports":[{"port":80,"protocol":"TCP"}]}]' | jq -cS .)
[ "$S" = "$E" ] && pass "Least permissive policy applied" || fail "allow-frontend-ns was modified"
