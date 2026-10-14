#!/bin/bash
# Setup for Question 11
mkdir -p /tmp/exam/q11 && chmod 777 /tmp/exam /tmp/exam/q11

C=/tmp/exam/q11/webapp
mkdir -p $C/templates
cat > $C/Chart.yaml <<'EOF'
apiVersion: v2
name: webapp
description: Small web application chart for the CKA Simulator lab
type: application
version: 1.0.0
appVersion: "1.25"
EOF
cat > $C/values.yaml <<'EOF'
replicaCount: 1
image:
  repository: nginx
  tag: "1.25"
service:
  port: 80
EOF
cat > $C/templates/deployment.yaml <<'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{ .Release.Name }}
  labels:
    app: {{ .Release.Name }}
spec:
  replicas: {{ .Values.replicaCount }}
  selector:
    matchLabels:
      app: {{ .Release.Name }}
  template:
    metadata:
      labels:
        app: {{ .Release.Name }}
    spec:
      containers:
      - name: web
        image: "{{ .Values.image.repository }}:{{ .Values.image.tag }}"
        ports:
        - containerPort: 80
EOF
cat > $C/templates/service.yaml <<'EOF'
apiVersion: v1
kind: Service
metadata:
  name: {{ .Release.Name }}
spec:
  selector:
    app: {{ .Release.Name }}
  ports:
  - port: {{ .Values.service.port }}
EOF
cat > /tmp/exam/q11/values-prod.yaml <<'EOF'
replicaCount: 2
service:
  port: 8080
EOF
chmod -R a+rwX /tmp/exam/q11

echo "Setup completed for Question 11"
exit 0
