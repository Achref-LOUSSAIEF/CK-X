#!/bin/bash
# Setup for Question 4
kubectl create namespace databases --dry-run=client -o yaml | kubectl apply -f -

kubectl apply -f - <<'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: db-app
  namespace: databases
spec:
  replicas: 2
  selector:
    matchLabels:
      app: db-app
  template:
    metadata:
      labels:
        app: db-app
    spec:
      containers:
      - name: app
        image: busybox:1.36
        command: ["sh", "-c", "while true; do sleep 3600; done"]
EOF

echo "Setup completed for Question 4"
exit 0
