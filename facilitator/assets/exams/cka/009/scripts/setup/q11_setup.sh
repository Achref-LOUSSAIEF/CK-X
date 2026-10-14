#!/bin/bash
# Setup for Question 11
kubectl create namespace shop --dry-run=client -o yaml | kubectl apply -f -

kubectl apply -f - <<'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: checkout
  namespace: shop
spec:
  replicas: 2
  selector:
    matchLabels:
      app: checkout
  template:
    metadata:
      labels:
        app: checkout
    spec:
      containers:
      - name: web
        image: nginx:1.27-alpien
EOF
kubectl annotate namespace shop ckx.io/checkout-uid="$(kubectl get deploy checkout -n shop -o jsonpath='{.metadata.uid}')" --overwrite

echo "Setup completed for Question 11"
exit 0
