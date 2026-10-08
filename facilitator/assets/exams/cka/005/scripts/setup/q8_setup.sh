#!/bin/bash
# Setup for Question 8
kubectl create namespace legacy --dry-run=client -o yaml | kubectl apply -f -

kubectl apply -f - <<'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: legacy-app
  namespace: legacy
spec:
  replicas: 2
  selector:
    matchLabels:
      app: legacy-app
  template:
    metadata:
      labels:
        app: legacy-app
    spec:
      containers:
      - name: app
        image: busybox:1.36
        command: ["sh", "-c", "mkdir -p /www && echo legacy-app > /www/index.html && httpd -f -p 3000 -h /www"]
        ports:
        - containerPort: 3000
---
apiVersion: v1
kind: Pod
metadata:
  name: probe
  namespace: legacy
spec:
  containers:
  - name: probe
    image: busybox:1.36
    command: ["sh", "-c", "while true; do sleep 3600; done"]
EOF

echo "Setup completed for Question 8"
exit 0
