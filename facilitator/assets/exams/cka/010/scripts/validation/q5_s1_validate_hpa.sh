#!/bin/bash
pass() { echo "✅ $1"; exit 0; }
fail() { echo "❌ $1"; exit 1; }
H=$(kubectl get hpa gateway -n payments -o json 2>/dev/null) || fail "HorizontalPodAutoscaler gateway not found"
echo "$H" | jq -e '.spec.scaleTargetRef.kind=="Deployment" and .spec.scaleTargetRef.name=="gateway" and .spec.minReplicas==2 and .spec.maxReplicas==6 and ([.spec.metrics[]? | select(.resource.name=="cpu" and .resource.target.averageUtilization==70)] | length == 1)' >/dev/null \
  && pass "HPA correct" || fail "gateway HPA must target Deployment gateway, min 2, max 6, CPU 70%"
