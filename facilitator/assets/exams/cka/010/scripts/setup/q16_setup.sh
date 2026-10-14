#!/bin/bash
# Setup for Question 16
kubectl create namespace analytics --dry-run=client -o yaml | kubectl apply -f -

kubectl apply -f - <<'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: analytics
  namespace: analytics
spec:
  replicas: 2
  selector:
    matchLabels:
      app: analytics
  template:
    metadata:
      labels:
        app: analytics
    spec:
      containers:
      - name: worker
        image: busybox:1.36
        command: ["sh", "-c", "while true; do sleep 3600; done"]
        resources:
          requests:
            cpu: "64"
            memory: 128Mi
EOF

echo "Setup completed for Question 16"
exit 0
