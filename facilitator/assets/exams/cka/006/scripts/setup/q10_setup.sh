#!/bin/bash
# Setup for Question 10
mkdir -p /tmp/exam/q10 && chmod 777 /tmp/exam /tmp/exam/q10
kubectl create namespace frontend --dry-run=client -o yaml | kubectl apply -f -
kubectl create namespace backend --dry-run=client -o yaml | kubectl apply -f -

kubectl apply -f - <<'EOF'
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: default-deny-ingress
  namespace: backend
spec:
  podSelector: {}
  policyTypes: ["Ingress"]
EOF
cat > /tmp/exam/q10/policy-1.yaml <<'EOF'
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-all-ingress
  namespace: backend
spec:
  podSelector: {}
  policyTypes: ["Ingress"]
  ingress:
  - {}
EOF
cat > /tmp/exam/q10/policy-2.yaml <<'EOF'
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-frontend-same-ns
  namespace: backend
spec:
  podSelector:
    matchLabels:
      app: backend
  policyTypes: ["Ingress"]
  ingress:
  - from:
    - podSelector:
        matchLabels:
          app: frontend
    ports:
    - protocol: TCP
      port: 80
EOF
cat > /tmp/exam/q10/policy-3.yaml <<'EOF'
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-frontend-ns
  namespace: backend
spec:
  podSelector:
    matchLabels:
      app: backend
  policyTypes: ["Ingress"]
  ingress:
  - from:
    - namespaceSelector:
        matchLabels:
          kubernetes.io/metadata.name: frontend
      podSelector:
        matchLabels:
          app: frontend
    ports:
    - protocol: TCP
      port: 80
EOF
cat > /tmp/exam/q10/policy-4.yaml <<'EOF'
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-frontend-any-port
  namespace: backend
spec:
  podSelector:
    matchLabels:
      app: backend
  policyTypes: ["Ingress"]
  ingress:
  - from:
    - namespaceSelector:
        matchLabels:
          kubernetes.io/metadata.name: frontend
EOF
chmod 444 /tmp/exam/q10/policy-*.yaml
kubectl create deployment backend -n backend --image=nginx:1.27 --dry-run=client -o yaml | kubectl apply -f -
kubectl create deployment frontend -n frontend --image=nginx:1.27 --dry-run=client -o yaml | kubectl apply -f -

echo "Setup completed for Question 10"
exit 0
