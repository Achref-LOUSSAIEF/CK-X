#!/bin/bash
# Setup for Question 14
kubectl create namespace archive --dry-run=client -o yaml | kubectl apply -f -

kubectl apply -f - <<'EOF'
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: archive-data
  namespace: archive
spec:
  storageClassName: premium
  accessModes: ["ReadWriteOnce"]
  resources:
    requests:
      storage: 1Gi
---
apiVersion: v1
kind: Pod
metadata:
  name: archive
  namespace: archive
spec:
  affinity:
    nodeAffinity:
      requiredDuringSchedulingIgnoredDuringExecution:
        nodeSelectorTerms:
        - matchExpressions:
          - key: kubernetes.io/hostname
            operator: NotIn
            values: ["k3d-cluster-agent-0"]
  containers:
  - name: archive
    image: busybox:1.36
    command: ["sh", "-c", "while true; do date >> /data/heartbeat; sleep 30; done"]
    volumeMounts:
    - name: data
      mountPath: /data
  volumes:
  - name: data
    persistentVolumeClaim:
      claimName: archive-data
EOF

echo "Setup completed for Question 14"
exit 0
