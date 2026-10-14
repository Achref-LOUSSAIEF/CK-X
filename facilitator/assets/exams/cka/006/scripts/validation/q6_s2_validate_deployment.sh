#!/bin/bash
pass() { echo "✅ $1"; exit 0; }
fail() { echo "❌ $1"; exit 1; }
C=$(kubectl get deploy queue-worker -n jobs -o jsonpath='{.spec.template.spec.priorityClassName}' 2>/dev/null) || fail "Deployment queue-worker not found"
[ "$C" = "urgent" ] || fail "queue-worker uses priorityClassName '$C'"
kubectl rollout status deploy/queue-worker -n jobs --timeout=30s >/dev/null 2>&1
for p in $(kubectl get pods -n jobs -l app=queue-worker --field-selector=status.phase=Running -o jsonpath='{.items[*].metadata.name}'); do
  [ "$(kubectl get pod "$p" -n jobs -o jsonpath='{.spec.priority}')" = "499999" ] || fail "Pod $p does not run with priority 499999"
done
R=$(kubectl get deploy queue-worker -n jobs -o jsonpath='{.status.readyReplicas}')
[ "${R:-0}" -eq 2 ] && pass "queue-worker uses urgent" || fail "queue-worker Ready replicas: ${R:-0}/2"
