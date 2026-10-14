#!/bin/bash
set -e

# Create namespace
kubectl create namespace gateway --dry-run=client -o yaml | kubectl apply -f -

# Install Gateway API CRDs
kubectl apply -f https://github.com/kubernetes-sigs/gateway-api/releases/download/v1.2.1/standard-install.yaml

# Wait for CRDs to be ready
kubectl wait --for=condition=established --timeout=60s crd/gateways.gateway.networking.k8s.io
kubectl wait --for=condition=established --timeout=60s crd/httproutes.gateway.networking.k8s.io

# GatewayClass referenced by the question (no controller is installed; only the resources are graded)
kubectl apply -f - <<EOF
apiVersion: gateway.networking.k8s.io/v1
kind: GatewayClass
metadata:
  name: ckx-gateway
spec:
  controllerName: ckx.io/gateway-controller
EOF

echo "Setup completed for Question 13" 