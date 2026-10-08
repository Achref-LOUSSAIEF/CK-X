#!/bin/bash
# Setup for Question 2
kubectl create namespace trbl-svc --dry-run=client -o yaml | kubectl apply -f -

kubectl apply -f - <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web
  namespace: trbl-svc
spec:
  replicas: 2
  selector:
    matchLabels:
      app: web-frontend
  template:
    metadata:
      labels:
        app: web-frontend
    spec:
      containers:
      - name: nginx
        image: nginx:1.25
        ports:
        - containerPort: 80
---
apiVersion: v1
kind: Service
metadata:
  name: web-svc
  namespace: trbl-svc
spec:
  selector:
    app: web-front
  ports:
  - port: 80
    targetPort: 8080
---
apiVersion: v1
kind: Pod
metadata:
  name: client
  namespace: trbl-svc
spec:
  nodeSelector:
    kubernetes.io/hostname: k3d-cluster-server-0
  containers:
  - name: client
    image: busybox:1.36
    command: ["sh", "-c", "while true; do sleep 3600; done"]
EOF

echo "Setup completed for Question 2"
exit 0
