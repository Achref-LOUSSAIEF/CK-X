#!/bin/bash
# Setup for Question 15
mkdir -p /tmp/exam/q15 && chmod 777 /tmp/exam /tmp/exam/q15
kubectl create namespace audit-lab --dry-run=client -o yaml | kubectl apply -f -

kubectl apply -f - <<'YAML'
apiVersion: v1
kind: Pod
metadata:
  name: web
  namespace: audit-lab
spec:
  containers:
  - name: web
    image: nginx:1.27
---
apiVersion: v1
kind: Pod
metadata:
  name: migrate
  namespace: audit-lab
spec:
  restartPolicy: Never
  containers:
  - name: migrate
    image: busybox:1.36
    command: ["sh", "-c", "echo migrated"]
---
apiVersion: v1
kind: Pod
metadata:
  name: importer
  namespace: audit-lab
spec:
  restartPolicy: Never
  containers:
  - name: importer
    image: busybox:1.36
    command: ["sh", "-c", "echo source unreachable; exit 3"]
---
apiVersion: v1
kind: Pod
metadata:
  name: cache
  namespace: audit-lab
spec:
  containers:
  - name: cache
    image: busybox:1.36
    command: ["sleep", "36000"]
---
apiVersion: v1
kind: Pod
metadata:
  name: analytics
  namespace: audit-lab
spec:
  nodeSelector:
    node-pool: does-not-exist
  containers:
  - name: analytics
    image: busybox:1.36
    command: ["sleep", "36000"]
YAML

echo "Setup completed for Question 15"
exit 0
