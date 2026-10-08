#!/bin/bash
# Setup for Question 15
mkdir -p /tmp/exam/q15 && chmod 777 /tmp/exam /tmp/exam/q15
kubectl create namespace storage-ops --dry-run=client -o yaml | kubectl apply -f -

kubectl apply -f - <<EOF
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: ledger-data
  namespace: storage-ops
spec:
  storageClassName: local-path
  accessModes: ["ReadWriteOnce"]
  resources:
    requests:
      storage: 1Gi
---
apiVersion: v1
kind: Pod
metadata:
  name: ledger
  namespace: storage-ops
spec:
  nodeSelector:
    kubernetes.io/hostname: k3d-cluster-server-0
  containers:
  - name: ledger
    image: busybox:1.36
    command: ["sh", "-c", "echo 'balance=100' > /data/ledger.txt; while true; do sleep 3600; done"]
    volumeMounts:
    - name: data
      mountPath: /data
  volumes:
  - name: data
    persistentVolumeClaim:
      claimName: ledger-data
EOF

echo "Setup completed for Question 15"
exit 0
