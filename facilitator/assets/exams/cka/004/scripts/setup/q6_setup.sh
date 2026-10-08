#!/bin/bash
# Setup for Question 6
mkdir -p /tmp/exam/helm-charts/monitoring/templates && chmod 777 /tmp/exam /tmp/exam/helm-charts/monitoring/templates

C=/tmp/exam/helm-charts/monitoring
cat > $C/Chart.yaml <<'EOF'
apiVersion: v2
name: monitoring
description: Minimal monitoring stack for the CK-X lab
type: application
version: 0.1.0
appVersion: "1.0"
EOF
cat > $C/values.yaml <<'EOF'
replica_count: 1
image: busybox:1.36
storage_size: 10Gi
persistence:
  enabled: false
EOF
cat > $C/templates/deployment.yaml <<'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{ .Release.Name }}
  labels:
    app: {{ .Release.Name }}
spec:
  replicas: {{ .Values.replica_count }}
  selector:
    matchLabels:
      app: {{ .Release.Name }}
  template:
    metadata:
      labels:
        app: {{ .Release.Name }}
    spec:
      containers:
      - name: collector
        image: {{ .Values.image }}
        command: ["sh", "-c", "while true; do sleep 3600; done"]
EOF
cat > $C/templates/pvc.yaml <<'EOF'
{{- if .Values.persistence.enabled }}
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: {{ .Release.Name }}-data
spec:
  accessModes: ["ReadWriteOnce"]
  resources:
    requests:
      storage: {{ .Values.storage_size }}
{{- end }}
EOF
chmod -R a+rwX /tmp/exam/helm-charts

echo "Setup completed for Question 6"
exit 0
