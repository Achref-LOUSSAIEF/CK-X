#!/bin/bash
# Setup for Question 16
mkdir -p /tmp/exam/q16 && chmod 777 /tmp/exam /tmp/exam/q16
kubectl create namespace observability --dry-run=client -o yaml | kubectl apply -f -

for p in trace-agent alert-router metrics-collector log-forwarder; do
  kubectl apply -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: $p
  namespace: observability
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
  - name: main
    image: busybox:1.36
    command: ["sh", "-c", "while true; do sleep 3600; done"]
EOF
  sleep 2
done

echo "Setup completed for Question 16"
exit 0
