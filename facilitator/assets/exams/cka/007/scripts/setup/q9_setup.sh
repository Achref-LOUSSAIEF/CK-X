#!/bin/bash
# Setup for Question 9
kubectl create namespace canary --dry-run=client -o yaml | kubectl apply -f -

kubectl apply -f https://github.com/kubernetes-sigs/gateway-api/releases/download/v1.2.1/standard-install.yaml
kubectl wait --for=condition=Established crd/gateways.gateway.networking.k8s.io crd/httproutes.gateway.networking.k8s.io --timeout=60s
kubectl apply -f - <<'EOF'
apiVersion: gateway.networking.k8s.io/v1
kind: GatewayClass
metadata:
  name: ckx-gateway
spec:
  controllerName: ckx.io/gateway-controller
---
apiVersion: gateway.networking.k8s.io/v1
kind: Gateway
metadata:
  name: edge
  namespace: canary
spec:
  gatewayClassName: ckx-gateway
  listeners:
  - name: http
    port: 80
    protocol: HTTP
EOF
for v in v1 v2; do
  kubectl create deployment store-$v -n canary --image=nginx:1.27 --dry-run=client -o yaml | kubectl apply -f -
  kubectl expose deployment store-$v -n canary --port=80 --dry-run=client -o yaml | kubectl apply -f -
done

echo "Setup completed for Question 9"
exit 0
