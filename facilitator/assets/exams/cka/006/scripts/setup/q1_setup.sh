#!/bin/bash
# Setup for Question 1
mkdir -p /tmp/exam/q1 && chmod 777 /tmp/exam /tmp/exam/q1
kubectl create namespace orders --dry-run=client -o yaml | kubectl apply -f -

kubectl apply -f - <<'EOF'
apiVersion: v1
kind: PersistentVolume
metadata:
  name: orders-pv
spec:
  capacity:
    storage: 500Mi
  accessModes: ["ReadWriteOnce"]
  persistentVolumeReclaimPolicy: Retain
  storageClassName: manual
  hostPath:
    path: /tmp/orders-pv
    type: DirectoryOrCreate
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: orders-old
  namespace: orders
spec:
  storageClassName: manual
  accessModes: ["ReadWriteOnce"]
  resources:
    requests:
      storage: 500Mi
EOF
for _ in $(seq 1 30); do
  [ "$(kubectl get pvc orders-old -n orders -o jsonpath='{.status.phase}')" = "Bound" ] && break; sleep 2
done
kubectl delete pvc orders-old -n orders --wait=true
kubectl annotate namespace orders ckx.io/orders-pv-uid="$(kubectl get pv orders-pv -o jsonpath='{.metadata.uid}')" --overwrite
cat > /tmp/exam/q1/orders-db.yaml <<'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: orders-db
  namespace: orders
spec:
  replicas: 1
  selector:
    matchLabels:
      app: orders-db
  template:
    metadata:
      labels:
        app: orders-db
    spec:
      containers:
      - name: mariadb
        image: mariadb:11
        env:
        - name: MARIADB_ALLOW_EMPTY_ROOT_PASSWORD
          value: "1"
        ports:
        - containerPort: 3306
EOF
chmod 666 /tmp/exam/q1/orders-db.yaml

echo "Setup completed for Question 1"
exit 0
