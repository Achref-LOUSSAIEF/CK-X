#!/bin/bash
# Setup for Question 7
mkdir -p /tmp/exam/q7 && chmod 777 /tmp/exam /tmp/exam/q7
kubectl create namespace cache --dry-run=client -o yaml | kubectl apply -f -

kubectl apply -f - <<'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: cache
  namespace: cache
spec:
  replicas: 3
  selector:
    matchLabels:
      app: cache
  template:
    metadata:
      labels:
        app: cache
    spec:
      containers:
      - name: cache
        image: busybox:1.36
        command: ["sh", "-c", "while true; do sleep 3600; done"]
        ports:
        - containerPort: 6379
          name: redis
EOF

echo "Setup completed for Question 7"
exit 0
