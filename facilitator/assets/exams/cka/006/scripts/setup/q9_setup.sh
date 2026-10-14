#!/bin/bash
# Setup for Question 9
kubectl create namespace store --dry-run=client -o yaml | kubectl apply -f -

kubectl apply -f - <<'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: store-api
  namespace: store
spec:
  replicas: 1
  selector:
    matchLabels:
      app: store-api
  template:
    metadata:
      labels:
        app: store-api
    spec:
      containers:
      - name: api
        image: nginx:1.27
        ports:
        - name: http
          containerPort: 80
---
apiVersion: v1
kind: Service
metadata:
  name: store-api
  namespace: store
spec:
  selector:
    app: store-api
  ports:
  - name: http
    port: 8080
    targetPort: http
---
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: store
  namespace: store
spec:
  ingressClassName: traefik
  rules:
  - host: store.example.local
    http:
      paths:
      - path: /api
        pathType: Exact
        backend:
          service:
            name: store-api
            port:
              number: 80
EOF

echo "Setup completed for Question 9"
exit 0
