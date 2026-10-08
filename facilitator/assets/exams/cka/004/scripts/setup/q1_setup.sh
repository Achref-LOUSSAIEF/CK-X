#!/bin/bash
# Setup for Question 1
kubectl create namespace production --dry-run=client -o yaml | kubectl apply -f -

kubectl apply -f - <<'EOF'
apiVersion: v1
kind: Pod
metadata:
  name: app-frontend
  namespace: production
  labels:
    app: app-frontend
spec:
  containers:
  - name: app
    image: busybox:1.36
    command: ["sh", "-c", "cat /etc/app/config.yaml || exit 1; while true; do sleep 3600; done"]
EOF

echo "Setup completed for Question 1"
exit 0
