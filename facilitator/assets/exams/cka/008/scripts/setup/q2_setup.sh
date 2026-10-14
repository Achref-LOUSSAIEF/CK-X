#!/bin/bash
# Setup for Question 2
kubectl create namespace frontend --dry-run=client -o yaml | kubectl apply -f -

kubectl apply -f - <<'EOF'
apiVersion: v1
kind: ConfigMap
metadata:
  name: frontend-config-v1
  namespace: frontend
immutable: true
data:
  LOG_LEVEL: info
  THEME: dark
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: frontend
  namespace: frontend
spec:
  replicas: 1
  selector:
    matchLabels:
      app: frontend
  template:
    metadata:
      labels:
        app: frontend
    spec:
      containers:
      - name: web
        image: busybox:1.36
        command: ["sh", "-c", "echo LOG_LEVEL=$LOG_LEVEL; sleep 3600"]
        envFrom:
        - configMapRef:
            name: frontend-config-v1
EOF

echo "Setup completed for Question 2"
exit 0
