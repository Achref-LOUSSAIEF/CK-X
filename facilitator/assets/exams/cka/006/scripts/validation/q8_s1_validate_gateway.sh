#!/bin/bash
pass() { echo "✅ $1"; exit 0; }
fail() { echo "❌ $1"; exit 1; }
G=$(kubectl get gateway.gateway.networking.k8s.io web-gateway -n web -o json 2>/dev/null) || fail "Gateway web-gateway not found"
echo "$G" | jq -e '.spec.gatewayClassName=="ckx-gateway"' >/dev/null || fail "gatewayClassName must be ckx-gateway"
echo "$G" | jq -e '[.spec.listeners[] | select(.name=="https" and .port==443 and .protocol=="HTTPS" and .hostname=="web.example.local"
  and (.tls.mode // "Terminate")=="Terminate" and ([.tls.certificateRefs[]? | select(.name=="web-tls")] | length > 0))] | length > 0' >/dev/null \
  && pass "Gateway correct" || fail "Listener https/443/HTTPS/web.example.local with certificateRef web-tls missing"
