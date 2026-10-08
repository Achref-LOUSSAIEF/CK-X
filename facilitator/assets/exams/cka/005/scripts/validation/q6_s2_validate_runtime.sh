#!/bin/bash
pass() { echo "✅ $1"; exit 0; }
fail() { echo "❌ $1"; exit 1; }
kubectl rollout status deploy/config-app -n config-reload --timeout=20s >/dev/null 2>&1 || fail "Rollout not complete"
PODS=$(kubectl get pods -n config-reload -l app=config-app --field-selector=status.phase=Running -o jsonpath='{.items[*].metadata.name}')
[ -n "$PODS" ] || fail "No running Pods"
for p in $PODS; do
  [ "$(kubectl exec "$p" -n config-reload -- printenv APP_MODE 2>/dev/null)" = "production" ] || fail "Pod $p still has the old APP_MODE"
  [ "$(kubectl exec "$p" -n config-reload -- cat /etc/app/APP_MODE 2>/dev/null)" = "production" ] || fail "Pod $p has no /etc/app/APP_MODE file"
done
pass "All Pods use production"
