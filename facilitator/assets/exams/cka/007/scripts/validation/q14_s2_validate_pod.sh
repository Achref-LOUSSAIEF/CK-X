#!/bin/bash
pass() { echo "✅ $1"; exit 0; }
fail() { echo "❌ $1"; exit 1; }
P=$(kubectl get pod archive -n archive -o json 2>/dev/null) || fail "Pod archive not found"
echo "$P" | jq -e '.spec.volumes[] | select(.persistentVolumeClaim.claimName=="archive-data")' >/dev/null || fail "archive does not use archive-data"
echo "$P" | jq -e '.spec.containers[0].volumeMounts[] | select(.mountPath=="/data")' >/dev/null || fail "archive-data must be mounted at /data"
[ "$(echo "$P" | jq -r '.status.phase')" = "Running" ] && pass "archive Running" || fail "archive is not Running"
