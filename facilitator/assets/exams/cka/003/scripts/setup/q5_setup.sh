#!/bin/bash
# Setup for Question 5
mkdir -p /tmp/exam/q5 && chmod 777 /tmp/exam /tmp/exam/q5
kubectl create namespace logging --dry-run=client -o yaml | kubectl apply -f -

kubectl apply -f - <<'EOF'
apiVersion: v1
kind: Pod
metadata:
  name: audit-app
  namespace: logging
spec:
  nodeSelector:
    kubernetes.io/hostname: k3d-cluster-server-0
  containers:
  - name: app
    image: busybox:1.36
    command:
    - sh
    - -c
    - |
      for i in $(seq 1 40); do
        if [ $((i % 4)) -eq 0 ]; then echo "txn=$i level=ERROR msg=payment declined";
        elif [ $((i % 7)) -eq 0 ]; then echo "txn=$i level=WARN msg=slow response";
        else echo "txn=$i level=INFO msg=payment accepted"; fi
      done
      while true; do sleep 3600; done
  - name: shipper
    image: busybox:1.36
    command:
    - sh
    - -c
    - |
      for i in $(seq 1 5); do echo "shipper ERROR upstream unreachable attempt=$i"; done
      while true; do sleep 3600; done
EOF

echo "Setup completed for Question 5"
exit 0
