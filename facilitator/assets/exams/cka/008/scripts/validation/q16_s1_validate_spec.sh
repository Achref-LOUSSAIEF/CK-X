#!/bin/bash
pass() { echo "✅ $1"; exit 0; }
fail() { echo "❌ $1"; exit 1; }
[ "$(kubectl get deploy orders -n orders -o jsonpath='{.spec.template.metadata.labels}' | jq -cS .)" = "$(kubectl get ns orders -o jsonpath='{.metadata.annotations.ckx\.io/orders-template}')" ] || fail "The Pod labels of the Deployment were changed"
S=$(kubectl get svc orders -n orders -o json 2>/dev/null) || fail "Service orders not found"
echo "$S" | jq -e '.spec.selector.app=="orders" and ((.spec.selector.tier // "backend")=="backend")' >/dev/null || fail "The Service selector does not match the orders Pods"
echo "$S" | jq -e '.spec.ports[0].port==80 and (.spec.ports[0].targetPort==80 or .spec.ports[0].targetPort=="http")' >/dev/null \
  && pass "Service fixed" || fail "Service port 80 must target the container port 80 (or 'http')"
