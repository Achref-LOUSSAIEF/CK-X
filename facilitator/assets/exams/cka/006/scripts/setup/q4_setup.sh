#!/bin/bash
# Setup for Question 4
kubectl create namespace checkout --dry-run=client -o yaml | kubectl apply -f -

kubectl apply -f - <<'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: checkout
  namespace: checkout
spec:
  replicas: 2
  selector:
    matchLabels:
      app: checkout
  template:
    metadata:
      labels:
        app: checkout
    spec:
      containers:
      - name: web
        image: nginx:1.27
        resources:
          requests:
            cpu: 50m
            memory: 32Mi
EOF

echo "Setup completed for Question 4"
exit 0
