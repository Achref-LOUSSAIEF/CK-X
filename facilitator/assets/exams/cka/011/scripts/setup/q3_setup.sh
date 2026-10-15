#!/bin/bash
# Setup for Question 3
kubectl create namespace dns-repair --dry-run=client -o yaml | kubectl apply -f -

# Send every name CoreDNS is not authoritative for to an address where no DNS server runs
kubectl get configmap coredns -n kube-system -o json \
  | jq '.data.Corefile |= sub("forward \\. [^\\s{]+"; "forward . 192.0.2.53")' \
  | kubectl apply -f -
kubectl rollout restart deployment coredns -n kube-system

kubectl run dns-client -n dns-repair --image=busybox:1.36 --restart=Never --dry-run=client -o yaml -- sleep 36000 | kubectl apply -f -

echo "Setup completed for Question 3"
exit 0
