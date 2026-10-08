#!/bin/bash
pass() { echo "✅ $1"; exit 0; }
fail() { echo "❌ $1"; exit 1; }
[ "$(kubectl get cm app-config -n config-reload -o jsonpath='{.data.APP_MODE}' 2>/dev/null)" = "production" ] || fail "APP_MODE is not production"
D=$(kubectl get deploy config-app -n config-reload -o json 2>/dev/null) || fail "Deployment config-app not found"
echo "$D" | jq -e '.spec.template.spec.volumes[]? | select(.name=="config") | .configMap.name=="app-config"' >/dev/null || fail "Volume config from ConfigMap app-config missing"
echo "$D" | jq -e '.spec.template.spec.containers[0].volumeMounts[]? | select(.name=="config") | .mountPath=="/etc/app" and (.subPath == null)' >/dev/null \
  && pass "Volume mounted" || fail "config must be mounted at /etc/app without subPath"
