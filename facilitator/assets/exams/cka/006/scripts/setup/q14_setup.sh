#!/bin/bash
# Setup for Question 14
kubectl create namespace reports --dry-run=client -o yaml | kubectl apply -f -

kubectl apply -f - <<'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: report-api
  namespace: reports
spec:
  replicas: 2
  selector:
    matchLabels:
      app: report-api
  template:
    metadata:
      labels:
        app: report-api
    spec:
      containers:
      - name: api
        image: nginx:1.27
        resources:
          requests:
            cpu: "16"
            memory: 64Gi
          limits:
            cpu: "16"
            memory: 64Gi
EOF
UID_RA=$(kubectl get deploy report-api -n reports -o jsonpath='{.metadata.uid}')
kubectl annotate namespace reports ckx.io/report-api-uid="$UID_RA" --overwrite

echo "Setup completed for Question 14"
exit 0
