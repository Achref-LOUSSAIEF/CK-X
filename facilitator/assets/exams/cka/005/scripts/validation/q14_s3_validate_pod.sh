#!/bin/bash
pass() { echo "✅ $1"; exit 0; }
fail() { echo "❌ $1"; exit 1; }
P=$(kubectl get pod app-using-ssd -n dyn-storage -o json 2>/dev/null) || fail "Pod app-using-ssd not found"
echo "$P" | jq -e '.spec.volumes[] | select(.name=="ssd-volume") | .persistentVolumeClaim.claimName=="my-ssd-claim"' >/dev/null || fail "Volume ssd-volume must use my-ssd-claim"
echo "$P" | jq -e '.spec.containers[0].volumeMounts[] | select(.name=="ssd-volume") | .mountPath=="/usr/share/nginx/html"' >/dev/null || fail "ssd-volume must be mounted at /usr/share/nginx/html"
[ "$(echo "$P" | jq -r '.status.phase')" = "Running" ] && pass "Pod running with the volume" || fail "Pod is not Running"
