#!/bin/bash
# Setup for Question 8
kubectl create namespace dev --dry-run=client -o yaml | kubectl apply -f -

kubectl apply -f - <<'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: api
  namespace: dev
spec:
  replicas: 1
  selector:
    matchLabels:
      app: api
  template:
    metadata:
      labels:
        app: api
    spec:
      containers:
      - name: web
        image: nginx:1.27
---
apiVersion: v1
kind: Pod
metadata:
  name: sink
  namespace: dev
  labels:
    app: other
spec:
  containers:
  - name: web
    image: nginx:1.27
---
apiVersion: v1
kind: Pod
metadata:
  name: restricted
  namespace: dev
  labels:
    role: restricted
spec:
  containers:
  - name: client
    image: busybox:1.36
    command: ["sleep", "36000"]
EOF

echo "Setup completed for Question 8"
exit 0
