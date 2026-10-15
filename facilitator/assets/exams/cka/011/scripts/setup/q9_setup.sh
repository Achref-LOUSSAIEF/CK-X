#!/bin/bash
# Setup for Question 9
mkdir -p /tmp/exam/q9 && chmod 777 /tmp/exam /tmp/exam/q9
kubectl create namespace oneoff --dry-run=client -o yaml | kubectl apply -f -

echo "Setup completed for Question 9"
exit 0
