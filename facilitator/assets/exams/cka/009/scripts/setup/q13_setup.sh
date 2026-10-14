#!/bin/bash
# Setup for Question 13
kubectl create namespace shop --dry-run=client -o yaml | kubectl apply -f -

kubectl apply -f - <<'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: orders
  namespace: shop
spec:
  replicas: 2
  selector:
    matchLabels:
      app: orders
  template:
    metadata:
      labels:
        app: orders
    spec:
      containers:
      - name: web
        image: nginx:1.27
        ports:
        - containerPort: 80
---
apiVersion: v1
kind: Service
metadata:
  name: orders-svc
  namespace: shop
spec:
  selector:
    app: order
  ports:
  - port: 80
    targetPort: 80
EOF

echo "Setup completed for Question 13"
exit 0
