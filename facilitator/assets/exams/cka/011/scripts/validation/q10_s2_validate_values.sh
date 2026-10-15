#!/bin/bash
pass() { echo "✅ $1"; exit 0; }
fail() { echo "❌ $1"; exit 1; }
V=$(helm get values edge -n edge -a -o json 2>/dev/null) || fail "Release edge not found"
echo "$V" | jq -e '.providers.kubernetesGateway.enabled==true and .providers.kubernetesIngress.enabled==true' >/dev/null || fail "Both the Gateway and the Ingress providers must be enabled"
helm get values edge -n edge -o json | jq -e '.providers.kubernetesGateway.enabled==true' >/dev/null || fail "Gateway support must be enabled through values, not by editing the chart"
grep -A3 'kubernetesGateway:' /tmp/exam/q10/edge-proxy/values.yaml | grep -q 'enabled: false' || fail "The chart's values.yaml must not be edited"
kubectl get deploy edge-edge-proxy -n edge -o json 2>/dev/null | jq -e '.spec.template.spec.containers[0].args | index("--providers.kubernetesgateway")' >/dev/null || fail "The Deployment does not enable the Gateway provider"
kubectl rollout status deploy/edge-edge-proxy -n edge --timeout=30s >/dev/null 2>&1 && pass "Gateway API support enabled" || fail "Deployment edge-edge-proxy is not available"
