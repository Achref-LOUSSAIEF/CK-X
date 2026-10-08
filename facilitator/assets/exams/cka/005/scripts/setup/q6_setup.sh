#!/bin/bash
# Setup for Question 6
kubectl create namespace config-reload --dry-run=client -o yaml | kubectl apply -f -

kubectl apply -f - <<'EOF'
apiVersion: v1
kind: ConfigMap
metadata:
  name: app-config
  namespace: config-reload
data:
  APP_MODE: development
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: config-app
  namespace: config-reload
spec:
  replicas: 2
  selector:
    matchLabels:
      app: config-app
  template:
    metadata:
      labels:
        app: config-app
    spec:
      containers:
      - name: app
        image: busybox:1.36
        command: ["sh", "-c", "echo mode=$APP_MODE; while true; do sleep 3600; done"]
        env:
        - name: APP_MODE
          valueFrom:
            configMapKeyRef:
              name: app-config
              key: APP_MODE
EOF

echo "Setup completed for Question 6"
exit 0
