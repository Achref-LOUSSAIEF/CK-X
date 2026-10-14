#!/bin/bash
# Setup for Question 4
kubectl create namespace shop --dry-run=client -o yaml | kubectl apply -f -

kubectl apply -f - <<'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: shop-v1
  namespace: shop
spec:
  replicas: 3
  selector:
    matchLabels:
      app: shop
      version: v1
  template:
    metadata:
      labels:
        app: shop
        version: v1
    spec:
      containers:
      - name: web
        image: nginx:1.25
---
apiVersion: v1
kind: Service
metadata:
  name: shop
  namespace: shop
spec:
  selector:
    app: shop
  ports:
  - port: 80
EOF

echo "Setup completed for Question 4"
exit 0
