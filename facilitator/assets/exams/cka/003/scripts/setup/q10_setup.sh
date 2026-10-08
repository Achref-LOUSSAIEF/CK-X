#!/bin/bash
# Setup for Question 10
kubectl create namespace ingress-lab --dry-run=client -o yaml | kubectl apply -f -

kubectl apply -f - <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: shop
  namespace: ingress-lab
spec:
  replicas: 1
  selector:
    matchLabels:
      app: shop
  template:
    metadata:
      labels:
        app: shop
    spec:
      containers:
      - name: nginx
        image: nginx:1.25
        ports:
        - containerPort: 80
EOF

kubectl apply -f - <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: api
  namespace: ingress-lab
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
      - name: nginx
        image: nginx:1.25
        ports:
        - containerPort: 80
EOF

echo "Setup completed for Question 10"
exit 0
