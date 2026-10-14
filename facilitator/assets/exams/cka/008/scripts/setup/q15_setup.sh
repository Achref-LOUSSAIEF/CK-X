#!/bin/bash
# Setup for Question 15
kubectl create namespace gw-lab --dry-run=client -o yaml | kubectl apply -f -
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
  name: public
  namespace: gw-lab
spec:
  gatewayClassName: ckx-gateway
  listeners:
  - name: http
    port: 80
    protocol: HTTP
EOF
for v in stable beta; do
  kubectl create deployment api-$v -n gw-lab --image=nginx:1.27 --dry-run=client -o yaml | kubectl apply -f -
  kubectl create service clusterip api-$v -n gw-lab --tcp=8080:80 --dry-run=client -o yaml | kubectl apply -f -
done

echo "Setup completed for Question 15"
exit 0
