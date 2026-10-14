#!/bin/bash
pass() { echo "✅ $1"; exit 0; }
fail() { echo "❌ $1"; exit 1; }
H=$(kubectl get hpa.v2.autoscaling checkout-hpa -n checkout -o json 2>/dev/null) || fail "HPA checkout-hpa not found"
echo "$H" | jq -e '.spec.scaleTargetRef.kind=="Deployment" and .spec.scaleTargetRef.name=="checkout"' >/dev/null || fail "HPA must target Deployment checkout"
echo "$H" | jq -e '.spec.minReplicas==2 and .spec.maxReplicas==8' >/dev/null || fail "min/max must be 2/8"
echo "$H" | jq -e '[.spec.metrics[]? | select(.type=="Resource" and .resource.name=="cpu" and .resource.target.type=="Utilization" and .resource.target.averageUtilization==60)] | length > 0' >/dev/null \
  && pass "HPA target correct" || fail "Target must be 60% average CPU utilization"
