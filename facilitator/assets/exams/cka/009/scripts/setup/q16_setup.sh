#!/bin/bash
# Setup for Question 16
kubectl create namespace reports --dry-run=client -o yaml | kubectl apply -f -

kubectl apply -f - <<'EOF'
apiVersion: v1
kind: ConfigMap
metadata:
  name: report-config
  namespace: reports
data:
  log_level: info
  format: pdf
---
apiVersion: v1
kind: Pod
metadata:
  name: report
  namespace: reports
spec:
  containers:
  - name: report
    image: busybox:1.36
    command: ["sh", "-c", "echo level=$LOG_LEVEL; sleep 3600"]
    env:
    - name: LOG_LEVEL
      valueFrom:
        configMapKeyRef:
          name: report-config
          key: LOG_LEVEL
EOF
kubectl annotate namespace reports ckx.io/report-uid="$(kubectl get pod report -n reports -o jsonpath='{.metadata.uid}')" --overwrite

echo "Setup completed for Question 16"
exit 0
