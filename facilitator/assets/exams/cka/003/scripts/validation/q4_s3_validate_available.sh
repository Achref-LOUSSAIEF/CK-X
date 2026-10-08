#!/bin/bash
pass() { echo "✅ $1"; exit 0; }
fail() { echo "❌ $1"; exit 1; }
REF=$(kubectl get deploy order-worker -n trbl-config -o jsonpath='{.spec.template.spec.containers[0].env[?(@.name=="QUEUE_NAME")].valueFrom.configMapKeyRef.key}')
[ "$REF" = "queue_name" ] || fail "Deployment was modified (QUEUE_NAME key ref is '$REF')"
kubectl rollout status deploy/order-worker -n trbl-config --timeout=20s >/dev/null 2>&1
A=$(kubectl get deploy order-worker -n trbl-config -o jsonpath='{.status.availableReplicas}')
[ "${A:-0}" -ge 1 ] && pass "order-worker available" || fail "order-worker has no available replica"
