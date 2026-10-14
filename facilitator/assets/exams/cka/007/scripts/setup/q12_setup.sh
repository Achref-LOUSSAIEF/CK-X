#!/bin/bash
# Setup for Question 12
kubectl create namespace ledger --dry-run=client -o yaml | kubectl apply -f -

kubectl taint node k3d-cluster-agent-0 maintenance=planned:NoSchedule --overwrite
kubectl apply -f - <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: ledger
  namespace: ledger
spec:
  replicas: 2
  selector:
    matchLabels:
      app: ledger
  template:
    metadata:
      labels:
        app: ledger
    spec:
      affinity:
        nodeAffinity:
          preferredDuringSchedulingIgnoredDuringExecution:
          - weight: 100
            preference:
              matchExpressions:
              - key: kubernetes.io/hostname
                operator: In
                values: ["k3d-cluster-agent-0"]
      tolerations:
      - key: maintenance
        operator: Equal
        value: planned
        effect: NoSchedule
      containers:
      - name: ledger
        image: busybox:1.36
        command: ["sh", "-c", "while true; do sleep 3600; done"]
---
apiVersion: policy/v1
kind: PodDisruptionBudget
metadata:
  name: ledger-pdb
  namespace: ledger
spec:
  minAvailable: 2
  selector:
    matchLabels:
      app: ledger
EOF

echo "Setup completed for Question 12"
exit 0
