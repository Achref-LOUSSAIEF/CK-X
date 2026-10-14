#!/bin/bash
# Setup for Question 3
kubectl create namespace billing --dry-run=client -o yaml | kubectl apply -f -

kubectl apply -f - <<'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: invoice-api
  namespace: billing
spec:
  replicas: 1
  selector:
    matchLabels:
      app: invoice-api
  template:
    metadata:
      labels:
        app: invoice-api
    spec:
      containers:
      - name: api
        image: busybox:1.36
        command: ["sh", "-c", "mkdir -p /var/log/invoice; i=0; while true; do i=$((i+1)); echo \"$(date) invoice=$i status=issued\" >> /var/log/invoice/app.log; sleep 2; done"]
EOF

echo "Setup completed for Question 3"
exit 0
