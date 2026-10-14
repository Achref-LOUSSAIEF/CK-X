#!/bin/bash
# Setup for Question 6
mkdir -p /tmp/exam/q6 && chmod 777 /tmp/exam /tmp/exam/q6
kubectl create namespace media --dry-run=client -o yaml | kubectl apply -f -
kubectl create deployment catalog -n media --image=nginx:1.25 --replicas=2 --dry-run=client -o yaml | kubectl apply -f -

echo "Setup completed for Question 6"
exit 0
