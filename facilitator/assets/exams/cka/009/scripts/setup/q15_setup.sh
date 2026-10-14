#!/bin/bash
# Setup for Question 15
kubectl create namespace www --dry-run=client -o yaml | kubectl apply -f -

kubectl apply -f - <<'EOF'
apiVersion: networking.k8s.io/v1
kind: IngressClass
metadata:
  name: nginx
spec:
  controller: k8s.io/ingress-nginx
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: www
  namespace: www
spec:
  replicas: 1
  selector:
    matchLabels:
      app: www
  template:
    metadata:
      labels:
        app: www
    spec:
      containers:
      - name: web
        image: nginx:1.27
---
apiVersion: v1
kind: Service
metadata:
  name: www
  namespace: www
spec:
  selector:
    app: www
  ports:
  - port: 80
EOF

echo "Setup completed for Question 15"
exit 0
