#!/bin/bash
# Setup for Question 7
kubectl create namespace db --dry-run=client -o yaml | kubectl apply -f -

kubectl apply -f - <<'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: db
  namespace: db
  labels:
    app: db
spec:
  replicas: 1
  selector:
    matchLabels:
      app: db
  template:
    metadata:
      labels:
        app: db
    spec:
      containers:
      - name: redis
        image: redis:7.2
        ports:
        - containerPort: 6379
---
apiVersion: v1
kind: Service
metadata:
  name: db
  namespace: db
spec:
  selector:
    app: db
  ports:
  - port: 6379
    targetPort: 6379
---
apiVersion: v1
kind: Pod
metadata:
  name: api-client
  namespace: db
  labels:
    role: api
spec:
  containers:
  - name: client
    image: busybox:1.36
    command: ["sleep", "3600"]
---
apiVersion: v1
kind: Pod
metadata:
  name: intruder
  namespace: db
  labels:
    role: web
spec:
  containers:
  - name: client
    image: busybox:1.36
    command: ["sleep", "3600"]
EOF

echo "Setup completed for Question 7"
exit 0
