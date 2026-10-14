#!/bin/bash
# Setup for Question 10
mkdir -p /tmp/exam/q10 && chmod 777 /tmp/exam /tmp/exam/q10
kubectl create namespace staging --dry-run=client -o yaml | kubectl apply -f -

mkdir -p /tmp/exam/q10/base /tmp/exam/q10/overlays
cat > /tmp/exam/q10/base/deployment.yaml <<'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: api
spec:
  replicas: 1
  selector:
    matchLabels:
      app: api
  template:
    metadata:
      labels:
        app: api
    spec:
      containers:
      - name: api
        image: nginx:1.25
        ports:
        - containerPort: 80
EOF
cat > /tmp/exam/q10/base/service.yaml <<'EOF'
apiVersion: v1
kind: Service
metadata:
  name: api
spec:
  selector:
    app: api
  ports:
  - port: 80
EOF
cat > /tmp/exam/q10/base/kustomization.yaml <<'EOF'
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
- deployment.yaml
- service.yaml
EOF
chmod -R a+rwX /tmp/exam/q10

echo "Setup completed for Question 10"
exit 0
