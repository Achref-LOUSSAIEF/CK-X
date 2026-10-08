#!/bin/bash
# Setup for Question 4
kubectl create namespace trbl-config --dry-run=client -o yaml | kubectl apply -f -

kubectl apply -f - <<EOF
apiVersion: v1
kind: ConfigMap
metadata:
  name: order-config
  namespace: trbl-config
data:
  queue-name: orders
  log_level: info
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: order-worker
  namespace: trbl-config
spec:
  replicas: 1
  selector:
    matchLabels:
      app: order-worker
  template:
    metadata:
      labels:
        app: order-worker
    spec:
      containers:
      - name: worker
        image: busybox:1.36
        command: ["sh", "-c", "echo queue=\$QUEUE_NAME; while true; do sleep 3600; done"]
        env:
        - name: DB_PASSWORD
          valueFrom:
            secretKeyRef:
              name: order-db
              key: password
        - name: QUEUE_NAME
          valueFrom:
            configMapKeyRef:
              name: order-config
              key: queue_name
EOF

echo "Setup completed for Question 4"
exit 0
