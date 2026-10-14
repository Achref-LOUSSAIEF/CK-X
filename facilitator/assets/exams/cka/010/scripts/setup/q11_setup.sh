#!/bin/bash
# Setup for Question 11
kubectl create namespace media --dry-run=client -o yaml | kubectl apply -f -
kubectl apply -f https://github.com/kubernetes-sigs/gateway-api/releases/download/v1.2.1/standard-install.yaml
kubectl wait --for=condition=Established crd/gateways.gateway.networking.k8s.io crd/httproutes.gateway.networking.k8s.io --timeout=60s

kubectl apply -f - <<'EOF'
apiVersion: gateway.networking.k8s.io/v1
kind: GatewayClass
metadata:
  name: nginx-gc
spec:
  controllerName: ckx.io/gateway-controller
EOF
kubectl create deployment media -n media --image=nginx:1.27 --dry-run=client -o yaml | kubectl apply -f -
kubectl expose deployment media -n media --port=80 --dry-run=client -o yaml | kubectl apply -f -

echo "Setup completed for Question 11"
exit 0
