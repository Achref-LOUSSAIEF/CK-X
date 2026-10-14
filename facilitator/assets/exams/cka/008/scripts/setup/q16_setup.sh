#!/bin/bash
# Setup for Question 16
kubectl create namespace orders --dry-run=client -o yaml | kubectl apply -f -

kubectl apply -f - <<'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: orders
  namespace: orders
spec:
  replicas: 2
  selector:
    matchLabels:
      app: orders
      tier: backend
  template:
    metadata:
      labels:
        app: orders
        tier: backend
    spec:
      containers:
      - name: web
        image: nginx:1.27
        ports:
        - containerPort: 80
          name: http
---
apiVersion: v1
kind: Service
metadata:
  name: orders
  namespace: orders
spec:
  selector:
    app: order
    tier: backend
  ports:
  - port: 80
    targetPort: 8080
EOF
kubectl annotate namespace orders ckx.io/orders-template="$(kubectl get deploy orders -n orders -o jsonpath='{.spec.template.metadata.labels}' | jq -cS .)" --overwrite

echo "Setup completed for Question 16"
exit 0
