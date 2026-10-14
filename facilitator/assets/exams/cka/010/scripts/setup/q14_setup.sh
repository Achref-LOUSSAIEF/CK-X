#!/bin/bash
# Setup for Question 14
kubectl create namespace payments --dry-run=client -o yaml | kubectl apply -f -
kubectl label node k3d-cluster-agent-1 zone=west pool=legacy --overwrite
kubectl taint node k3d-cluster-agent-1 pool=legacy:NoSchedule --overwrite

kubectl apply -f - <<'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: legacy
  namespace: payments
spec:
  replicas: 2
  selector:
    matchLabels:
      app: legacy
  template:
    metadata:
      labels:
        app: legacy
    spec:
      nodeSelector:
        pool: legacy
      tolerations:
      - key: pool
        operator: Equal
        value: legacy
        effect: NoSchedule
      containers:
      - name: app
        image: busybox:1.36
        command: ["sh", "-c", "while true; do sleep 3600; done"]
EOF

echo "Setup completed for Question 14"
exit 0
