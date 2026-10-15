#!/bin/bash
# Setup for Question 14
kubectl apply -f https://github.com/kubernetes-sigs/gateway-api/releases/download/v1.2.1/standard-install.yaml
kubectl wait --for=condition=Established crd/gateways.gateway.networking.k8s.io crd/httproutes.gateway.networking.k8s.io --timeout=60s

kubectl create namespace infra --dry-run=client -o yaml | kubectl apply -f -
kubectl create namespace web-app --dry-run=client -o yaml | kubectl apply -f -

kubectl apply -f - <<'YAML'
apiVersion: gateway.networking.k8s.io/v1
kind: GatewayClass
metadata:
  name: shared-gw-class
spec:
  controllerName: ckx.io/gateway-controller
---
apiVersion: gateway.networking.k8s.io/v1
kind: Gateway
metadata:
  name: shared-gw
  namespace: infra
spec:
  gatewayClassName: shared-gw-class
  listeners:
  - name: http
    protocol: HTTP
    port: 80
    allowedRoutes:
      namespaces:
        from: Same
YAML
kubectl create deployment web-service -n web-app --image=nginx:1.27 --port=80 --dry-run=client -o yaml | kubectl apply -f -
kubectl expose deployment web-service -n web-app --port=80 --dry-run=client -o yaml | kubectl apply -f -

echo "Setup completed for Question 14"
exit 0
