#!/bin/bash
# Reference solution for CKA lab 005 (Mock Exam 02).
# Usage (in the exam terminal): bash answers.sh

# Q1 - DNS
echo "web-ui.frontend.svc.cluster.local" > /tmp/exam/q1/dns-name.txt
kubectl run dns-test -n backend --image=busybox:1.36 -- sleep 3600
kubectl wait --for=condition=Ready pod/dns-test -n backend --timeout=60s
kubectl exec dns-test -n backend -- nslookup web-ui.frontend.svc.cluster.local > /tmp/exam/q1/nslookup.txt

# Q2 - rollout history and rollback
kubectl rollout history deploy/payment-service -n payments
echo 3 > /tmp/exam/q2/bad-revision.txt
kubectl rollout undo deploy/payment-service -n payments --to-revision=2

# Q3 - Secret as environment variables
kubectl create secret generic db-creds -n app-secrets \
  --from-literal=username=dbuser --from-literal=password=secret123 --from-literal=database=appdb
kubectl apply -f - <<'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: db-client
  namespace: app-secrets
spec:
  replicas: 1
  selector:
    matchLabels:
      app: db-client
  template:
    metadata:
      labels:
        app: db-client
    spec:
      containers:
      - name: app
        image: busybox:1.36
        command: ["sleep", "3600"]
        env:
        - name: DB_USERNAME
          valueFrom:
            secretKeyRef: {name: db-creds, key: username}
        - name: DB_PASSWORD
          valueFrom:
            secretKeyRef: {name: db-creds, key: password}
        - name: DB_DATABASE
          valueFrom:
            secretKeyRef: {name: db-creds, key: database}
EOF

# Q4 - DaemonSet tolerating the control-plane taint
kubectl apply -f - <<'EOF'
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: monitoring-agent
  namespace: monitoring
spec:
  selector:
    matchLabels:
      app: monitoring-agent
  template:
    metadata:
      labels:
        app: monitoring-agent
    spec:
      tolerations:
      - key: node-role.kubernetes.io/control-plane
        operator: Exists
        effect: NoSchedule
      containers:
      - name: agent
        image: busybox:1.36
        command: ["sh", "-c", "while true; do sleep 3600; done"]
EOF

# Q5 - API server health through the API
kubectl get --raw='/readyz?verbose' > /tmp/exam/q5/readyz.txt
kubectl get endpointslices -n default -l kubernetes.io/service-name=kubernetes \
  -o jsonpath='{.items[0].ports[0].port}' > /tmp/exam/q5/apiserver-port.txt

# Q6 - update the ConfigMap, mount it, restart the Pods
kubectl patch cm app-config -n config-reload --type=merge -p '{"data":{"APP_MODE":"production"}}'
kubectl patch deploy config-app -n config-reload --type=json -p='[
  {"op":"add","path":"/spec/template/spec/volumes","value":[{"name":"config","configMap":{"name":"app-config"}}]},
  {"op":"add","path":"/spec/template/spec/containers/0/volumeMounts","value":[{"name":"config","mountPath":"/etc/app"}]}]'
kubectl rollout restart deploy/config-app -n config-reload   # needed if the volume already existed

# Q7 - PriorityClasses
kubectl create priorityclass critical --value=1000 --description="critical workloads"
kubectl create priorityclass standard --value=100 --description="standard workloads"
for p in critical-pod-1:critical critical-pod-2:critical standard-pod:standard; do
  kubectl run "${p%%:*}" -n priority-lab --image=nginx:1.25 \
    --overrides="{\"spec\":{\"priorityClassName\":\"${p#*:}\"}}"
done

# Q8 - NodePort Service
kubectl apply -f - <<'EOF'
apiVersion: v1
kind: Service
metadata:
  name: legacy-app
  namespace: legacy
spec:
  type: NodePort
  selector:
    app: legacy-app
  ports:
  - port: 8080
    targetPort: 3000
    nodePort: 30808
EOF

# Q9 - suspended CronJob
kubectl create cronjob backup-job -n backups --image=busybox:1.36 --schedule="0 2 * * *" \
  --dry-run=client -o json -- sh -c 'echo backup done' \
  | jq '.spec.suspend=true | .spec.successfulJobsHistoryLimit=3 | .spec.jobTemplate.spec.template.spec.containers[0].name="backup"' \
  | kubectl apply -f -
# resume later with: kubectl patch cronjob backup-job -n backups -p '{"spec":{"suspend":false}}'

# Q10 - CertificateSigningRequest
kubectl apply -f - <<EOF
apiVersion: certificates.k8s.io/v1
kind: CertificateSigningRequest
metadata:
  name: john
spec:
  request: $(base64 -w0 < /tmp/exam/q10/john.csr)
  signerName: kubernetes.io/kube-apiserver-client
  expirationSeconds: 86400
  usages: ["client auth"]
EOF
kubectl certificate approve john
sleep 3
kubectl get csr john -o jsonpath='{.status.certificate}' | base64 -d > /tmp/exam/q10/john.crt

# Q11 - PodDisruptionBudget
kubectl create pdb app-pdb -n pdb-lab --selector=app=web-app --max-unavailable=2

# Q12 - custom resources
kubectl get crd | grep -i database
kubectl apply -f - <<'EOF'
apiVersion: stable.example.com/v1
kind: Database
metadata:
  name: prod-db
  namespace: crd-db
spec:
  engine: postgres
  version: "16"
  storageGB: 20
EOF
kubectl delete database legacy-db -n crd-db

# Q13 - separate namespace for the root Pod
kubectl create namespace privileged-apps
kubectl label namespace privileged-apps pod-security.kubernetes.io/enforce=baseline
kubectl run privileged-pod -n privileged-apps --image=nginx:1.25 \
  --overrides='{"spec":{"securityContext":{"runAsUser":0}}}'

# Q14 - dynamic provisioning
kubectl apply -f - <<'EOF'
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: ssd-provisioner
provisioner: rancher.io/local-path
volumeBindingMode: WaitForFirstConsumer
reclaimPolicy: Delete
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: my-ssd-claim
  namespace: dyn-storage
spec:
  storageClassName: ssd-provisioner
  accessModes: ["ReadWriteOnce"]
  resources:
    requests:
      storage: 20Gi
---
apiVersion: v1
kind: Pod
metadata:
  name: app-using-ssd
  namespace: dyn-storage
spec:
  containers:
  - name: app
    image: nginx:1.25
    volumeMounts:
    - name: ssd-volume
      mountPath: /usr/share/nginx/html
  volumes:
  - name: ssd-volume
    persistentVolumeClaim:
      claimName: my-ssd-claim
EOF

# Q15 - ResourceQuota + LimitRange
kubectl create quota batch-jobs-quota -n batch-jobs --hard=limits.cpu=10,limits.memory=20Gi
kubectl apply -f - <<'EOF'
apiVersion: v1
kind: LimitRange
metadata:
  name: batch-jobs-limits
  namespace: batch-jobs
spec:
  limits:
  - type: Container
    min:
      cpu: 500m
      memory: 256Mi
    max:
      cpu: "4"
      memory: 8Gi
    default:
      cpu: "1"
      memory: 1Gi
    defaultRequest:
      cpu: 500m
      memory: 256Mi
EOF
