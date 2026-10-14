#!/bin/bash
pass() { echo "✅ $1"; exit 0; }
fail() { echo "❌ $1"; exit 1; }
U=$(kubectl get deploy checkout -n shop -o jsonpath='{.metadata.uid}' 2>/dev/null) || fail "Deployment checkout not found"
[ "$U" = "$(kubectl get ns shop -o jsonpath='{.metadata.annotations.ckx\.io/checkout-uid}')" ] || fail "checkout was deleted and recreated"
[ "$(kubectl get deploy checkout -n shop -o jsonpath='{.spec.template.spec.containers[0].image}')" = "nginx:1.27-alpine" ] \
  && pass "Image fixed" || fail "checkout must use nginx:1.27-alpine"
