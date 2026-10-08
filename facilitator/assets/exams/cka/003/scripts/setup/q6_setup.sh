#!/bin/bash
# Setup for Question 6
mkdir -p /tmp/exam/q6 && chmod 777 /tmp/exam /tmp/exam/q6
kubectl create namespace metrics-lab --dry-run=client -o yaml | kubectl apply -f -

kubectl apply -f - <<'EOF'
apiVersion: v1
kind: Pod
metadata:
  name: analytics-1
  namespace: metrics-lab
  labels:
    app: analytics
spec:
  nodeSelector:
    kubernetes.io/hostname: k3d-cluster-server-0
  containers:
  - name: worker
    image: busybox:1.36
    command: ["sh", "-c", "while true; do sleep 3600; done"]
    resources:
      requests:
        cpu: 10m
      limits:
        cpu: 250m
        memory: 32Mi
EOF

kubectl apply -f - <<'EOF'
apiVersion: v1
kind: Pod
metadata:
  name: analytics-2
  namespace: metrics-lab
  labels:
    app: analytics
spec:
  nodeSelector:
    kubernetes.io/hostname: k3d-cluster-server-0
  containers:
  - name: worker
    image: busybox:1.36
    command: ["sh", "-c", "while true; do :; done"]
    resources:
      requests:
        cpu: 10m
      limits:
        cpu: 250m
        memory: 32Mi
EOF

kubectl apply -f - <<'EOF'
apiVersion: v1
kind: Pod
metadata:
  name: analytics-3
  namespace: metrics-lab
  labels:
    app: analytics
spec:
  nodeSelector:
    kubernetes.io/hostname: k3d-cluster-server-0
  containers:
  - name: worker
    image: busybox:1.36
    command: ["sh", "-c", "while true; do sleep 3600; done"]
    resources:
      requests:
        cpu: 10m
      limits:
        cpu: 250m
        memory: 32Mi
EOF

echo "Setup completed for Question 6"
exit 0
