#!/bin/bash
# Question 4, step 2: Service web-server-nginx is a NodePort on 30080
svc=$(kubectl get service web-server-nginx -n default -o json 2>/dev/null) || { echo "❌ Service 'web-server-nginx' not found"; exit 1; }
[ "$(echo "$svc" | jq -r '.spec.type')" = "NodePort" ] || { echo "❌ Service type is not NodePort"; exit 1; }
# the chart exposes http and https: one of them must use node port 30080
echo "$svc" | jq -e '[.spec.ports[] | select(.nodePort == 30080)] | length > 0' >/dev/null \
  && { echo "✅ NodePort Service with node port 30080"; exit 0; } \
  || { echo "❌ No port uses node port 30080: $(echo "$svc" | jq -c '[.spec.ports[] | {name, nodePort}]')"; exit 1; }
