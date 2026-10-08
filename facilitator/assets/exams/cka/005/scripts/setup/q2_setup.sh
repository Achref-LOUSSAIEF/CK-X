#!/bin/bash
# Setup for Question 2
mkdir -p /tmp/exam/q2 && chmod 777 /tmp/exam /tmp/exam/q2
kubectl create namespace payments --dry-run=client -o yaml | kubectl apply -f -

kubectl apply -f - <<'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: payment-service
  namespace: payments
  annotations:
    kubernetes.io/change-cause: "initial release nginx:1.24"
spec:
  replicas: 3
  selector:
    matchLabels:
      app: payment-service
  template:
    metadata:
      labels:
        app: payment-service
    spec:
      containers:
      - name: payment
        image: nginx:1.24
EOF
sleep 2
kubectl set image deploy/payment-service payment=nginx:1.25 -n payments
kubectl annotate deploy/payment-service -n payments kubernetes.io/change-cause="upgrade to nginx:1.25" --overwrite
sleep 2
kubectl set image deploy/payment-service payment=nginx:1.25-hotfix -n payments
kubectl annotate deploy/payment-service -n payments kubernetes.io/change-cause="hotfix release" --overwrite

echo "Setup completed for Question 2"
exit 0
