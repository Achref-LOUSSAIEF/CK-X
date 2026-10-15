#!/bin/bash
# Setup for Question 6
mkdir -p /tmp/exam/q6 && chmod 777 /tmp/exam /tmp/exam/q6
kubectl create namespace init-lab --dry-run=client -o yaml | kubectl apply -f -

cat > /tmp/exam/q6/ledger.yaml <<'YAML'
apiVersion: v1
kind: Pod
metadata:
  name: ledger
  namespace: init-lab
spec:
  containers:
  - name: app
    image: busybox:1.36
    command:
    - sh
    - -c
    - |
      if [ ! -f /workdir/ready.flag ]; then
        echo "ready.flag not found, exiting"
        exit 1
      fi
      echo "ledger started"
      sleep 36000
    volumeMounts:
    - name: workdir
      mountPath: /workdir
  volumes:
  - name: workdir
    emptyDir: {}
YAML
chmod 666 /tmp/exam/q6/ledger.yaml

echo "Setup completed for Question 6"
exit 0
