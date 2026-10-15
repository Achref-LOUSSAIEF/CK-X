#!/bin/bash
# Setup for Question 1
mkdir -p /tmp/exam/q1 && chmod 777 /tmp/exam /tmp/exam/q1
kubectl create namespace web-logs --dry-run=client -o yaml | kubectl apply -f -

kubectl apply -f - <<'YAML'
apiVersion: v1
kind: Pod
metadata:
  name: bar
  namespace: web-logs
spec:
  containers:
  - name: bar
    image: busybox:1.36
    command:
    - sh
    - -c
    - |
      echo "INFO  checker started, 4 sites configured"
      echo "INFO  GET https://shop.example.com 200 112ms"
      echo "WARN  GET https://blog.example.com 301 redirect followed"
      echo "ERROR unable-to-access-website https://legacy.example.com timeout after 5s"
      echo "INFO  GET https://docs.example.com 200 87ms"
      echo "ERROR unable-to-access-website https://partners.example.com connection refused"
      echo "INFO  retrying failed sites in 30s"
      echo "ERROR dns lookup failed for https://cdn.example.com"
      echo "ERROR unable-to-access-website https://legacy.example.com timeout after 5s"
      echo "INFO  round finished: 2 ok, 1 redirect, 3 failed"
      sleep 36000
YAML

echo "Setup completed for Question 1"
exit 0
