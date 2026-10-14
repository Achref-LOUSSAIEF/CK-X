#!/bin/bash
# Setup for Question 12
mkdir -p /tmp/exam/q12 && chmod 777 /tmp/exam /tmp/exam/q12
kubectl create namespace monitoring --dry-run=client -o yaml | kubectl apply -f -

for p in prometheus alertmanager node-exporter; do
  kubectl run "$p" -n monitoring --image=busybox:1.36 --restart=Never --dry-run=client -o yaml -- sleep 36000 | kubectl apply -f -
done
kubectl apply -f - <<'EOF'
apiVersion: v1
kind: Pod
metadata:
  name: log-shipper
  namespace: monitoring
spec:
  containers:
  - name: shipper
    image: busybox:1.36
    command: ["sh", "-c", "while true; do :; done"]
    resources:
      limits:
        cpu: 250m
EOF

echo "Setup completed for Question 12"
exit 0
