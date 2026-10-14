#!/bin/bash
# Setup for Question 4
kubectl create namespace startup --dry-run=client -o yaml | kubectl apply -f -

kubectl apply -f - <<'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: database
  namespace: startup
spec:
  replicas: 1
  selector:
    matchLabels:
      app: database
  template:
    metadata:
      labels:
        app: database
    spec:
      containers:
      - name: db
        image: busybox:1.36
        command: ["sh", "-c", "while true; do sleep 3600; done"]
---
apiVersion: v1
kind: Service
metadata:
  name: database
  namespace: startup
spec:
  selector:
    app: database
  ports:
  - port: 5432
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: api
  namespace: startup
spec:
  replicas: 1
  selector:
    matchLabels:
      app: api
  template:
    metadata:
      labels:
        app: api
    spec:
      initContainers:
      - name: wait-db
        image: busybox:1.36
        command: ["sh", "-c", "until nslookup db.startup.svc.cluster.local; do echo waiting for db; sleep 2; done"]
      containers:
      - name: api
        image: busybox:1.36
        command: ["sh", "-c", "echo api started; sleep 3600"]
EOF
kubectl annotate namespace startup ckx.io/database-svc-uid="$(kubectl get svc database -n startup -o jsonpath='{.metadata.uid}')" --overwrite

echo "Setup completed for Question 4"
exit 0
