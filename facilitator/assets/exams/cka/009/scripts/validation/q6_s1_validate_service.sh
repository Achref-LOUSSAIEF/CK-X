#!/bin/bash
pass() { echo "✅ $1"; exit 0; }
fail() { echo "❌ $1"; exit 1; }
S=$(kubectl get svc api-svc -n backend -o json 2>/dev/null) || fail "Service api-svc not found"
echo "$S" | jq -e '.spec.type=="ClusterIP" and .spec.ports[0].port==8080 and (.spec.ports[0].targetPort==80) and .spec.selector.app=="api"' >/dev/null \
  && pass "api-svc correct" || fail "api-svc must be ClusterIP, port 8080, targetPort 80, selector app=api"
