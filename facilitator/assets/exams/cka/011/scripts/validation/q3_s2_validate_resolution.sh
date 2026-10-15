#!/bin/bash
pass() { echo "✅ $1"; exit 0; }
fail() { echo "❌ $1"; exit 1; }
kubectl wait --for=condition=Ready pod/dns-client -n dns-repair --timeout=30s >/dev/null 2>&1 || fail "The Pod dns-client is not Ready"
SVC=$(kubectl get svc kubernetes -n default -o jsonpath='{.spec.clusterIP}')
kubectl exec -n dns-repair dns-client -- nslookup kubernetes.default.svc.cluster.local 2>/dev/null | grep -q "$SVC" || fail "Cluster names no longer resolve"
for i in 1 2 3; do
  kubectl exec -n dns-repair dns-client -- nslookup kubernetes.io. 2>/dev/null | grep -A3 '^Name:' | grep -q 'Address' && pass "Cluster and external names resolve"
  sleep 3
done
fail "External names (kubernetes.io) do not resolve from Pods"
