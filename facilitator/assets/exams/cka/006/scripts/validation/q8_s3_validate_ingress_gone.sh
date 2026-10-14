#!/bin/bash
pass() { echo "✅ $1"; exit 0; }
fail() { echo "❌ $1"; exit 1; }
kubectl get ingress web -n web >/dev/null 2>&1 && fail "Ingress web still exists"
kubectl get gateway.gateway.networking.k8s.io web-gateway -n web >/dev/null 2>&1 || fail "Create the Gateway before deleting the Ingress"
pass "Ingress removed"
