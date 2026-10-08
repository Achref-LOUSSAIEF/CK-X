#!/bin/bash
# Setup for Question 7
kubectl create namespace maintenance --dry-run=client -o yaml | kubectl apply -f -

kubectl apply -f - <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: maint-web
  namespace: maintenance
spec:
  replicas: 3
  selector:
    matchLabels:
      app: maint-web
  template:
    metadata:
      labels:
        app: maint-web
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
      containers:
      - name: nginx
        image: nginx:1.25
EOF

echo "Setup completed for Question 7"
exit 0
