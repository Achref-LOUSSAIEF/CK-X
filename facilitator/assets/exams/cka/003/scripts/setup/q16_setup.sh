#!/bin/bash
# Setup for Question 16
mkdir -p /tmp/exam/q16 && chmod 777 /tmp/exam /tmp/exam/q16
kubectl create namespace ci --dry-run=client -o yaml | kubectl apply -f -

echo "Setup completed for Question 16"
exit 0
