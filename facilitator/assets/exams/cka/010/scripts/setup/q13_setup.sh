#!/bin/bash
# Setup for Question 13
mkdir -p /tmp/exam/q13 && chmod 777 /tmp/exam /tmp/exam/q13
kubectl create namespace payments --dry-run=client -o yaml | kubectl apply -f -
kubectl create secret generic license -n payments --from-literal=key=LIC-7731-EAST --dry-run=client -o yaml | kubectl apply -f -

echo "Setup completed for Question 13"
exit 0
