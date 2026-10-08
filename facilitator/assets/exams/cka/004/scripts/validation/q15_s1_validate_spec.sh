#!/bin/bash
pass() { echo "✅ $1"; exit 0; }
fail() { echo "❌ $1"; exit 1; }
P=$(kubectl get pod app-with-logger -n default -o json 2>/dev/null) || fail "Pod app-with-logger not found"
echo "$P" | jq -e '.spec.volumes[] | select(.name=="log-volume") | .emptyDir != null' >/dev/null || fail "emptyDir volume log-volume required"
echo "$P" | jq -e '.spec.containers[] | select(.name=="nginx") | .volumeMounts[] | select(.name=="log-volume") | .mountPath=="/var/log/nginx"' >/dev/null || fail "nginx must mount log-volume at /var/log/nginx"
echo "$P" | jq -e '.spec.containers[] | select(.name=="logger") | .volumeMounts[] | select(.name=="log-volume") | .mountPath=="/logs"' >/dev/null \
  && pass "Spec correct" || fail "logger must mount log-volume at /logs"
