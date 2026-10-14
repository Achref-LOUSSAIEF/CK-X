#!/bin/bash
# Setup for Question 17
kubectl create namespace metrics --dry-run=client -o yaml | kubectl apply -f -

kubectl apply -f - <<'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: exporter
  namespace: metrics
spec:
  replicas: 1
  selector:
    matchLabels:
      app: exporter
  template:
    metadata:
      labels:
        app: exporter
    spec:
      containers:
      - name: exporter
        image: busybox:1.36
        command: ["sh", "-c", "while true; do sleep 3600; done"]
        ports:
        - name: http
          containerPort: 8080
        - name: metrics
          containerPort: 9100
EOF

echo "Setup completed for Question 17"
exit 0
