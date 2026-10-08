#!/bin/bash
# Setup for Question 1
kubectl create namespace trbl-deploy --dry-run=client -o yaml | kubectl apply -f -

kubectl apply -f - <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: payment-api
  namespace: trbl-deploy
spec:
  replicas: 2
  selector:
    matchLabels:
      app: payment-api
  template:
    metadata:
      labels:
        app: payment-api
    spec:
      containers:
      - name: api
        image: nginx:1.25-alpne
        ports:
        - containerPort: 80
        readinessProbe:
          httpGet:
            path: /
            port: 8080
          initialDelaySeconds: 2
          periodSeconds: 5
EOF

echo "Setup completed for Question 1"
exit 0
