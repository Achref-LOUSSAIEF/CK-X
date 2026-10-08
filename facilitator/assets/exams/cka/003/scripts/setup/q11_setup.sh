#!/bin/bash
# Setup for Question 11
kubectl create namespace np-db --dry-run=client -o yaml | kubectl apply -f -
kubectl create namespace np-backend --dry-run=client -o yaml | kubectl apply -f -
kubectl label namespace np-backend team=backend --overwrite
kubectl create namespace np-other --dry-run=client -o yaml | kubectl apply -f -
kubectl label namespace np-other team=frontend --overwrite

kubectl apply -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: db
  namespace: np-db
  labels:
    app: db
spec:
  nodeSelector:
    kubernetes.io/hostname: k3d-cluster-server-0
  containers:
  - name: db
    image: nginx:1.25
    ports:
    - containerPort: 80
---
apiVersion: v1
kind: Service
metadata:
  name: db
  namespace: np-db
spec:
  selector:
    app: db
  ports:
  - port: 80
    targetPort: 80
EOF
for p in "np-backend api api" "np-backend worker worker" "np-other api api"; do
set -- $p
kubectl apply -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: $2
  namespace: $1
  labels:
    role: $3
spec:
  nodeSelector:
    kubernetes.io/hostname: k3d-cluster-server-0
  containers:
  - name: client
    image: busybox:1.36
    command: ["sh", "-c", "while true; do sleep 3600; done"]
EOF
done

echo "Setup completed for Question 11"
exit 0
