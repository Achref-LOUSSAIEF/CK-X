#!/bin/bash
# Setup for Question 10: a local Helm chart
C=/tmp/exam/q10/edge-proxy
mkdir -p $C/templates && chmod 777 /tmp/exam /tmp/exam/q10

cat > $C/Chart.yaml <<'YAML'
apiVersion: v2
name: edge-proxy
description: A small edge proxy whose routing providers are switched on by values
type: application
version: 1.4.0
appVersion: "1.4.0"
YAML

cat > $C/values.yaml <<'YAML'
replicaCount: 1

image:
  repository: busybox
  tag: "1.36"

# Where the proxy reads its routing rules from
providers:
  kubernetesIngress:
    enabled: true
  kubernetesGateway:
    enabled: false
YAML

cat > $C/templates/configmap.yaml <<'YAML'
apiVersion: v1
kind: ConfigMap
metadata:
  name: {{ .Release.Name }}-edge-proxy
  labels:
    app.kubernetes.io/instance: {{ .Release.Name }}
data:
  providers.yaml: |
    kubernetesIngress: {{ .Values.providers.kubernetesIngress.enabled }}
    kubernetesGateway: {{ .Values.providers.kubernetesGateway.enabled }}
YAML

cat > $C/templates/deployment.yaml <<'YAML'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{ .Release.Name }}-edge-proxy
  labels:
    app.kubernetes.io/instance: {{ .Release.Name }}
spec:
  replicas: {{ .Values.replicaCount }}
  selector:
    matchLabels:
      app.kubernetes.io/instance: {{ .Release.Name }}
  template:
    metadata:
      labels:
        app.kubernetes.io/instance: {{ .Release.Name }}
    spec:
      containers:
      - name: proxy
        image: "{{ .Values.image.repository }}:{{ .Values.image.tag }}"
        args:
        - sh
        - -c
        - sleep 36000
        {{- if .Values.providers.kubernetesIngress.enabled }}
        - --providers.kubernetesingress
        {{- end }}
        {{- if .Values.providers.kubernetesGateway.enabled }}
        - --providers.kubernetesgateway
        {{- end }}
YAML
chmod -R a+rwX /tmp/exam/q10

echo "Setup completed for Question 10"
exit 0
