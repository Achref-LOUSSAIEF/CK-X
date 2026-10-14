#!/bin/bash
pass() { echo "✅ $1"; exit 0; }
fail() { echo "❌ $1"; exit 1; }
P=$(kubectl get pod log-pair -n logs -o json 2>/dev/null) || fail "Pod log-pair not found"
echo "$P" | jq -e '[.spec.volumes[] | select(.name=="shared" and .emptyDir.medium=="Memory" and .emptyDir.sizeLimit=="64Mi")] | length == 1' >/dev/null || fail "Volume shared must be an emptyDir with medium Memory and sizeLimit 64Mi"
echo "$P" | jq -e '[.spec.containers[] | select(.name=="writer") | .volumeMounts[]? | select(.name=="shared" and .mountPath=="/var/log/app")] | length == 1' >/dev/null || fail "writer must mount shared at /var/log/app"
echo "$P" | jq -e '[.spec.containers[] | select(.name=="reader") | .volumeMounts[]? | select(.name=="shared" and .mountPath=="/logs" and .readOnly==true)] | length == 1' >/dev/null \
  && pass "Volumes correct" || fail "reader must mount shared read-only at /logs"
