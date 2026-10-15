#!/bin/bash
# Setup for Question 12
mkdir -p /tmp/exam/q12 && chmod 777 /tmp/exam /tmp/exam/q12

pv() {
  cat <<YAML
---
apiVersion: v1
kind: PersistentVolume
metadata:
  name: $1
  labels:
    team: storage-audit
spec:
  capacity:
    storage: $2
  accessModes: ["ReadWriteOnce"]
  persistentVolumeReclaimPolicy: Retain
  storageClassName: audit-manual
  hostPath:
    path: /mnt/audit/$1
YAML
}
{ pv pv-logs 3Gi; pv pv-media 500Mi; pv pv-backup 10Gi; pv pv-cache 1Gi; pv pv-scratch 64Mi; } | kubectl apply -f -

echo "Setup completed for Question 12"
exit 0
