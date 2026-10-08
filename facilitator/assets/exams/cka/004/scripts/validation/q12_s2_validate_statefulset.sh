#!/bin/bash
pass() { echo "✅ $1"; exit 0; }
fail() { echo "❌ $1"; exit 1; }
S=$(kubectl get sts database-cluster -n db-cluster -o json 2>/dev/null) || fail "StatefulSet database-cluster not found"
echo "$S" | jq -e '.spec.replicas==3 and .spec.serviceName=="database-cluster"' >/dev/null || fail "Need 3 replicas and serviceName database-cluster"
echo "$S" | jq -e '.spec.template.spec.containers[] | select(.name=="postgres") | .image=="postgres:16-alpine"' >/dev/null || fail "Container postgres with postgres:16-alpine required"
echo "$S" | jq -e '.spec.volumeClaimTemplates[] | select(.metadata.name=="db-storage") | .spec.resources.requests.storage=="10Gi"' >/dev/null || fail "volumeClaimTemplate db-storage of 10Gi required"
echo "$S" | jq -e '.spec.template.spec.containers[] | select(.name=="postgres") | .volumeMounts[] | select(.name=="db-storage") | .mountPath=="/var/lib/postgresql/data"' >/dev/null \
  && pass "StatefulSet spec correct" || fail "db-storage must be mounted at /var/lib/postgresql/data"
