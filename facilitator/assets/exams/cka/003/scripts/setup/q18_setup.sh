#!/bin/bash
# Setup for Question 18
kubectl create namespace trbl-dns --dry-run=client -o yaml | kubectl apply -f -

kubectl apply -f - <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: resolver
  namespace: trbl-dns
spec:
  replicas: 1
  selector:
    matchLabels:
      app: resolver
  template:
    metadata:
      labels:
        app: resolver
    spec:
      dnsPolicy: "None"
      dnsConfig:
        nameservers: ["10.255.255.1"]
        searches: ["svc.local"]
      containers:
      - name: tools
        image: busybox:1.36
        command: ["sh", "-c", "while true; do sleep 3600; done"]
EOF

echo "Setup completed for Question 18"
exit 0
