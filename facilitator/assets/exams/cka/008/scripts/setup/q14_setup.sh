#!/bin/bash
# Setup for Question 14
mkdir -p /tmp/exam/q14 && chmod 777 /tmp/exam /tmp/exam/q14
kubectl create namespace inventory --dry-run=client -o yaml | kubectl apply -f -

kubectl apply -f - <<'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: catalog
  namespace: inventory
spec:
  replicas: 2
  selector:
    matchLabels:
      app: catalog
  template:
    metadata:
      labels:
        app: catalog
    spec:
      initContainers:
      - name: migrate
        image: alpine:3.20
        command: ["sh", "-c", "echo migrated"]
      containers:
      - name: web
        image: nginx:1.27
      - name: metrics
        image: registry.k8s.io/pause:3.10
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: stock
  namespace: inventory
spec:
  replicas: 1
  selector:
    matchLabels:
      app: stock
  template:
    metadata:
      labels:
        app: stock
    spec:
      containers:
      - name: api
        image: nginx:1.25
      - name: sidecar
        image: busybox:1.36
        command: ["sh", "-c", "while true; do sleep 3600; done"]
EOF

echo "Setup completed for Question 14"
exit 0
