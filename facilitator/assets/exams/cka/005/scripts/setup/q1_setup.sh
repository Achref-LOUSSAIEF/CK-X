#!/bin/bash
# Setup for Question 1
mkdir -p /tmp/exam/q1 && chmod 777 /tmp/exam /tmp/exam/q1
kubectl create namespace frontend --dry-run=client -o yaml | kubectl apply -f -
kubectl create namespace backend --dry-run=client -o yaml | kubectl apply -f -

kubectl apply -f - <<'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web-ui
  namespace: frontend
spec:
  replicas: 1
  selector:
    matchLabels:
      app: web-ui
  template:
    metadata:
      labels:
        app: web-ui
    spec:
      containers:
      - name: web
        image: busybox:1.36
        command: ["sh", "-c", "mkdir -p /www && echo web-ui > /www/index.html && httpd -f -p 3000 -h /www"]
        ports:
        - containerPort: 3000
---
apiVersion: v1
kind: Service
metadata:
  name: web-ui
  namespace: frontend
spec:
  selector:
    app: web-ui
  ports:
  - port: 3000
    targetPort: 3000
EOF

echo "Setup completed for Question 1"
exit 0
