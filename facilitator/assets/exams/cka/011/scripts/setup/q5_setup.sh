#!/bin/bash
# Setup for Question 5
mkdir -p /tmp/exam/q5 && chmod 777 /tmp/exam /tmp/exam/q5
kubectl create namespace lookup --dry-run=client -o yaml | kubectl apply -f -
kubectl create deployment nginx-random -n lookup --image=nginx:1.27 --port=80 --dry-run=client -o yaml | kubectl apply -f -

echo "Setup completed for Question 5"
exit 0
