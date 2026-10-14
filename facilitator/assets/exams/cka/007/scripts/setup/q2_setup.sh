#!/bin/bash
# Setup for Question 2
kubectl create namespace sales --dry-run=client -o yaml | kubectl apply -f -

kubectl apply -f - <<'EOF'
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: default-deny-egress
  namespace: sales
spec:
  podSelector: {}
  policyTypes: ["Egress"]
---
apiVersion: v1
kind: Pod
metadata:
  name: sales-client
  namespace: sales
  labels:
    app: sales-client
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
  - name: client
    image: busybox:1.36
    command: ["sh", "-c", "while true; do sleep 3600; done"]
EOF

echo "Setup completed for Question 2"
exit 0
