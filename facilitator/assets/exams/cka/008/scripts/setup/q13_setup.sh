#!/bin/bash
# Setup for Question 13
mkdir -p /tmp/exam/q13 && chmod 777 /tmp/exam /tmp/exam/q13
kubectl create namespace checkout --dry-run=client -o yaml | kubectl apply -f -

kubectl create deployment checkout -n checkout --image=nginx:1.25 --replicas=2 --dry-run=client -o yaml | kubectl apply -f -
kubectl annotate deployment checkout -n checkout kubernetes.io/change-cause="initial release" --overwrite
sleep 2
kubectl set image deployment/checkout -n checkout nginx=nginx:1.26
kubectl annotate deployment checkout -n checkout kubernetes.io/change-cause="update to 1.26" --overwrite
sleep 2
kubectl set image deployment/checkout -n checkout nginx=nginx:1.27
kubectl annotate deployment checkout -n checkout kubernetes.io/change-cause="update to 1.27" --overwrite
sleep 2
kubectl set image deployment/checkout -n checkout nginx=nginx:1.99-broken
kubectl annotate deployment checkout -n checkout kubernetes.io/change-cause="update to 1.99" --overwrite

echo "Setup completed for Question 13"
exit 0
