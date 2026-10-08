#!/bin/bash
pass() { echo "✅ $1"; exit 0; }
fail() { echo "❌ $1"; exit 1; }
kubectl rollout status deploy/spread-web -n spread-lab --timeout=20s >/dev/null 2>&1
A=0; B=0; T=0
for n in $(kubectl get pods -n spread-lab -l app=spread-web --field-selector=status.phase=Running -o jsonpath='{.items[*].spec.nodeName}'); do
  Z=$(kubectl get node "$n" -o jsonpath='{.metadata.labels.topology\.ckx\.io/zone}')
  T=$((T+1)); [ "$Z" = "zone-a" ] && A=$((A+1)); [ "$Z" = "zone-b" ] && B=$((B+1))
done
[ "$T" -eq 4 ] || fail "$T/4 Pods Running"
[ "$A" -eq 2 ] && [ "$B" -eq 2 ] && pass "zone-a=$A zone-b=$B" || fail "Uneven spread: zone-a=$A zone-b=$B"
