#!/bin/bash
pass() { echo "✅ $1"; exit 0; }
fail() { echo "❌ $1"; exit 1; }
H=$(kubectl get hpa.v2.autoscaling web-app-hpa -n production -o json 2>/dev/null) || fail "HPA web-app-hpa not found"
echo "$H" | jq -e '.spec.scaleTargetRef.kind=="Deployment" and .spec.scaleTargetRef.name=="web-app"' >/dev/null || fail "HPA must target Deployment web-app"
echo "$H" | jq -e '.spec.minReplicas==2 and .spec.maxReplicas==10' >/dev/null || fail "min/max replicas must be 2/10"
echo "$H" | jq -e '[.spec.metrics[]? | select(.type=="Resource" and .resource.name=="cpu" and .resource.target.type=="Utilization" and .resource.target.averageUtilization==70)] | length > 0' >/dev/null \
  && pass "HPA correct" || fail "Target must be 70% average CPU utilization"
