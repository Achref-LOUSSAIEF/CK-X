#!/bin/bash
# Setup for Question 5
kubectl create namespace payments --dry-run=client -o yaml | kubectl apply -f -

kubectl apply -f - <<'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: gateway
  namespace: payments
spec:
  replicas: 2
  selector:
    matchLabels:
      app: gateway
  template:
    metadata:
      labels:
        app: gateway
    spec:
      containers:
      - name: web
        image: nginx:1.27
        resources:
          requests:
            cpu: 50m
EOF

echo "Setup completed for Question 5"
exit 0
