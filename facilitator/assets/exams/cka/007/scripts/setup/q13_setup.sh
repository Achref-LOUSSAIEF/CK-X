#!/bin/bash
# Setup for Question 13
mkdir -p /tmp/exam/q13 && chmod 777 /tmp/exam /tmp/exam/q13
kubectl create namespace reporting --dry-run=client -o yaml | kubectl apply -f -

kubectl apply -f - <<'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: report-gen
  namespace: reporting
spec:
  replicas: 1
  selector:
    matchLabels:
      app: report-gen
  template:
    metadata:
      labels:
        app: report-gen
    spec:
      containers:
      - name: report
        image: busybox:1.36
        command: ["sh", "-c", "echo starting report generator; sleeep 3600"]
EOF

echo "Setup completed for Question 13"
exit 0
