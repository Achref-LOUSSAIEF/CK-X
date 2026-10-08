#!/bin/bash
# Setup for Question 8
mkdir -p /tmp/exam/q8 && chmod 777 /tmp/exam /tmp/exam/q8
kubectl create namespace audit-lab --dry-run=client -o yaml | kubectl apply -f -

for sa in reporter deployer ci auditor; do kubectl create sa $sa -n audit-lab --dry-run=client -o yaml | kubectl apply -f -; done
kubectl apply -f - <<'EOF'
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: configmap-reader
rules:
- apiGroups: [""]
  resources: ["configmaps"]
  verbs: ["get", "list"]
EOF
kubectl create rolebinding reporter-view -n audit-lab --clusterrole=view --serviceaccount=audit-lab:reporter --dry-run=client -o yaml | kubectl apply -f -
kubectl create rolebinding app-config-readers -n default --clusterrole=configmap-reader --serviceaccount=audit-lab:deployer --dry-run=client -o yaml | kubectl apply -f -
kubectl create rolebinding pipeline-edit -n default --clusterrole=edit --serviceaccount=audit-lab:ci --dry-run=client -o yaml | kubectl apply -f -
kubectl create rolebinding public-readers -n kube-public --clusterrole=configmap-reader --serviceaccount=audit-lab:auditor --dry-run=client -o yaml | kubectl apply -f -

echo "Setup completed for Question 8"
exit 0
