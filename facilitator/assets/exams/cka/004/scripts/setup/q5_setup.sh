#!/bin/bash
# Setup for Question 5
kubectl create namespace shop --dry-run=client -o yaml | kubectl apply -f -

for p in "frontend 80" "backend 3000" "database 5432"; do
set -- $p
kubectl apply -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: $1
  namespace: shop
  labels:
    tier: $1
spec:
  containers:
  - name: app
    image: busybox:1.36
    command: ["sh", "-c", "mkdir -p /www && echo $1 > /www/index.html && httpd -f -p $2 -h /www"]
    ports:
    - containerPort: $2
EOF
done
kubectl apply -f - <<'EOF'
apiVersion: v1
kind: Pod
metadata:
  name: tester
  namespace: shop
spec:
  containers:
  - name: app
    image: busybox:1.36
    command: ["sh", "-c", "while true; do sleep 3600; done"]
EOF

echo "Setup completed for Question 5"
exit 0
