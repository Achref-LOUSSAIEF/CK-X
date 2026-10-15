#!/bin/bash
# Setup for Question 8
kubectl create namespace blog --dry-run=client -o yaml | kubectl apply -f -

# The requests were copied from a much bigger cluster: no node can fit a single Pod
kubectl apply -f - <<'YAML'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: cms
  namespace: blog
spec:
  replicas: 3
  selector:
    matchLabels:
      app: cms
  template:
    metadata:
      labels:
        app: cms
    spec:
      nodeSelector:
        kubernetes.io/hostname: k3d-cluster-agent-1
      initContainers:
      - name: init-content
        image: busybox:1.36
        command: ["sh", "-c", "echo '<h1>blog</h1>' > /content/index.html"]
        resources:
          requests:
            cpu: "64"
            memory: 256Gi
        volumeMounts:
        - name: content
          mountPath: /content
      containers:
      - name: cms
        image: nginx:1.27
        resources:
          requests:
            cpu: "64"
            memory: 256Gi
        volumeMounts:
        - name: content
          mountPath: /usr/share/nginx/html
      volumes:
      - name: content
        emptyDir: {}
YAML

echo "Setup completed for Question 8"
exit 0
