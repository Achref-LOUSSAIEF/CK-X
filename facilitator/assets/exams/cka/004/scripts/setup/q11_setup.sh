#!/bin/bash
# Setup for Question 11
kubectl create namespace sched-debug --dry-run=client -o yaml | kubectl apply -f -

kubectl apply -f - <<'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: report-generator
  namespace: sched-debug
spec:
  replicas: 2
  selector:
    matchLabels:
      app: report-generator
  template:
    metadata:
      labels:
        app: report-generator
    spec:
      schedulerName: custom-scheduler
      containers:
      - name: report
        image: busybox:1.36
        command: ["sh", "-c", "while true; do sleep 3600; done"]
EOF

echo "Setup completed for Question 11"
exit 0
