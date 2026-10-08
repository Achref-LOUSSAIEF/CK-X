#!/bin/bash
# Setup for Question 3
kubectl create namespace maintenance --dry-run=client -o yaml | kubectl apply -f -

kubectl apply -f - <<'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web-tier
  namespace: maintenance
spec:
  replicas: 3
  selector:
    matchLabels:
      app: web-tier
  template:
    metadata:
      labels:
        app: web-tier
    spec:
      affinity:
        nodeAffinity:
          preferredDuringSchedulingIgnoredDuringExecution:
          - weight: 100
            preference:
              matchExpressions:
              - key: kubernetes.io/hostname
                operator: In
                values: ["k3d-cluster-agent-1"]
      containers:
      - name: nginx
        image: nginx:1.25
---
apiVersion: v1
kind: Pod
metadata:
  name: db-local
  namespace: maintenance
  labels:
    app: db-local
spec:
  nodeName: k3d-cluster-agent-1
  containers:
  - name: db
    image: busybox:1.36
    command: ["sh", "-c", "echo 'row=1' > /data/db.txt; while true; do sleep 3600; done"]
    volumeMounts:
    - name: data
      mountPath: /data
  volumes:
  - name: data
    emptyDir: {}
EOF
UID_DB=$(kubectl get pod db-local -n maintenance -o jsonpath='{.metadata.uid}')
kubectl annotate namespace maintenance ckx.io/db-local-uid="$UID_DB" --overwrite

echo "Setup completed for Question 3"
exit 0
