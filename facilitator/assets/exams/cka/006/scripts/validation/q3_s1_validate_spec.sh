#!/bin/bash
pass() { echo "✅ $1"; exit 0; }
fail() { echo "❌ $1"; exit 1; }
D=$(kubectl get deploy invoice-api -n billing -o json 2>/dev/null) || fail "Deployment invoice-api not found"
T='.spec.template.spec'
echo "$D" | jq -e "$T.volumes[]? | select(.name==\"logs\") | .emptyDir != null" >/dev/null || fail "emptyDir volume logs missing"
echo "$D" | jq -e "$T.containers[] | select(.name==\"api\") | .volumeMounts[]? | select(.name==\"logs\") | .mountPath==\"/var/log/invoice\"" >/dev/null || fail "api must mount logs at /var/log/invoice"
echo "$D" | jq -e "$T.initContainers[]? | select(.name==\"log-shipper\") | .restartPolicy==\"Always\" and .image==\"busybox:1.36\"" >/dev/null || fail "log-shipper must be an init container with restartPolicy Always and image busybox:1.36"
echo "$D" | jq -e "$T.initContainers[] | select(.name==\"log-shipper\") | .volumeMounts[]? | select(.name==\"logs\") | .mountPath==\"/var/log/invoice\"" >/dev/null \
  && pass "Sidecar configured" || fail "log-shipper must mount logs at /var/log/invoice"
