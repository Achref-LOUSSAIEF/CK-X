#!/bin/bash
# Setup for Question 3
kubectl create namespace trbl-sched --dry-run=client -o yaml | kubectl apply -f -

kubectl apply -f - <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: batch-processor
  namespace: trbl-sched
spec:
  replicas: 2
  selector:
    matchLabels:
      app: batch-processor
  template:
    metadata:
      labels:
        app: batch-processor
    spec:
      nodeSelector:
        disktype: nvme
      containers:
      - name: processor
        image: nginx:1.25
        resources:
          requests:
            cpu: "64"
            memory: 64Mi
EOF

echo "Setup completed for Question 3"
exit 0
