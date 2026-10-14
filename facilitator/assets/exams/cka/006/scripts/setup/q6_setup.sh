#!/bin/bash
# Setup for Question 6
kubectl create namespace jobs --dry-run=client -o yaml | kubectl apply -f -

for pc in "batch-low 1000" "batch-default 50000" "critical-batch 500000" "nightly-reports 2500"; do
  set -- $pc
  kubectl create priorityclass "$1" --value="$2" --description="CKA Simulator lab" --dry-run=client -o yaml | kubectl apply -f -
done
kubectl apply -f - <<'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: queue-worker
  namespace: jobs
spec:
  replicas: 2
  selector:
    matchLabels:
      app: queue-worker
  template:
    metadata:
      labels:
        app: queue-worker
    spec:
      priorityClassName: batch-low
      containers:
      - name: worker
        image: busybox:1.36
        command: ["sh", "-c", "while true; do sleep 3600; done"]
EOF

echo "Setup completed for Question 6"
exit 0
