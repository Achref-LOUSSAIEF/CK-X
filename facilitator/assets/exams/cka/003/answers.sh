#!/bin/bash
# Reference solution for CKA lab 003 - applies every answer in order.
# Usage (on the jumphost): KUBECONFIG=/home/candidate/.kube/kubeconfig bash answers.sh

# Q1 - fix image typo and readiness probe port
kubectl set image deploy/payment-api api=nginx:1.25-alpine -n trbl-deploy
kubectl patch deploy payment-api -n trbl-deploy --type=json \
  -p='[{"op":"replace","path":"/spec/template/spec/containers/0/readinessProbe/httpGet/port","value":80}]'

# Q2 - fix the Service selector and targetPort
kubectl patch svc web-svc -n trbl-svc --type=merge \
  -p '{"spec":{"selector":{"app":"web-frontend"},"ports":[{"port":80,"targetPort":80,"protocol":"TCP"}]}}'

# Q3 - remove impossible nodeSelector and fix CPU request
kubectl patch deploy batch-processor -n trbl-sched --type=json -p='[
  {"op":"remove","path":"/spec/template/spec/nodeSelector"},
  {"op":"replace","path":"/spec/template/spec/containers/0/resources/requests/cpu","value":"100m"}]'

# Q4 - create the missing Secret and ConfigMap key
kubectl create secret generic order-db -n trbl-config --from-literal=password='Sup3rS3cret!'
kubectl patch cm order-config -n trbl-config --type=merge -p '{"data":{"queue_name":"orders"}}'

# Q5 - logs of a specific container + node name
kubectl logs audit-app -n logging -c app | grep ERROR > /tmp/exam/q5/errors.log
kubectl get pod audit-app -n logging -o jsonpath='{.spec.nodeName}' > /tmp/exam/q5/node.txt

# Q6 - highest CPU pod
kubectl top pod -n metrics-lab -l app=analytics --sort-by=cpu --no-headers | head -1 | awk '{print $1}' > /tmp/exam/q6/top-pod.txt

# Q7 - cordon + drain
kubectl drain k3d-cluster-agent-0 --ignore-daemonsets --delete-emptydir-data

# Q8 - RBAC
kubectl create clusterrole node-viewer --verb=get,list,watch --resource=nodes,persistentvolumes
kubectl create clusterrolebinding jane-node-viewer --clusterrole=node-viewer --user=jane
kubectl create role deploy-manager -n rbac-lab --verb=get,list,create,update,patch,delete --resource=deployments
kubectl create rolebinding developers-deploy-manager -n rbac-lab --role=deploy-manager --group=developers

# Q9 - CRD + custom resource
kubectl apply -f - <<'EOF'
apiVersion: apiextensions.k8s.io/v1
kind: CustomResourceDefinition
metadata:
  name: backups.ops.example.com
spec:
  group: ops.example.com
  scope: Namespaced
  names:
    kind: Backup
    plural: backups
    singular: backup
    shortNames: ["bk"]
  versions:
  - name: v1
    served: true
    storage: true
    schema:
      openAPIV3Schema:
        type: object
        properties:
          spec:
            type: object
            required: ["schedule"]
            properties:
              schedule:
                type: string
              retentionDays:
                type: integer
                minimum: 1
EOF
kubectl wait --for=condition=Established crd/backups.ops.example.com --timeout=30s
kubectl apply -f - <<'EOF'
apiVersion: ops.example.com/v1
kind: Backup
metadata:
  name: nightly
  namespace: crd-lab
spec:
  schedule: "0 2 * * *"
  retentionDays: 7
EOF

# Q10 - Services + Ingress
kubectl expose deploy shop -n ingress-lab --name=shop-svc --port=80 --target-port=80
kubectl expose deploy api -n ingress-lab --name=api-svc --port=8080 --target-port=80
kubectl create ingress shop-ingress -n ingress-lab --class=traefik \
  --rule="shop.example.local/api*=api-svc:8080" --rule="shop.example.local/*=shop-svc:80"

# Q11 - NetworkPolicies
kubectl apply -f - <<'EOF'
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: default-deny-ingress
  namespace: np-db
spec:
  podSelector: {}
  policyTypes: ["Ingress"]
---
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-backend-api
  namespace: np-db
spec:
  podSelector:
    matchLabels:
      app: db
  policyTypes: ["Ingress"]
  ingress:
  - from:
    - namespaceSelector:
        matchLabels:
          team: backend
      podSelector:
        matchLabels:
          role: api
    ports:
    - protocol: TCP
      port: 80
EOF

# Q12 - DaemonSet
kubectl apply -f - <<'EOF'
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: node-agent
  namespace: ds-lab
spec:
  selector:
    matchLabels:
      app: node-agent
  template:
    metadata:
      labels:
        app: node-agent
    spec:
      tolerations:
      - operator: Exists
      containers:
      - name: agent
        image: busybox:1.36
        command: ["sh", "-c", "while true; do sleep 3600; done"]
        resources:
          requests:
            cpu: 10m
            memory: 16Mi
        volumeMounts:
        - name: varlog
          mountPath: /host/log
          readOnly: true
      volumes:
      - name: varlog
        hostPath:
          path: /var/log
EOF

# Q13 - CronJob + manual Job
kubectl apply -f - <<'EOF'
apiVersion: batch/v1
kind: CronJob
metadata:
  name: log-cleanup
  namespace: batch-lab
spec:
  schedule: "*/15 * * * *"
  concurrencyPolicy: Forbid
  successfulJobsHistoryLimit: 2
  failedJobsHistoryLimit: 1
  jobTemplate:
    spec:
      backoffLimit: 2
      activeDeadlineSeconds: 60
      template:
        spec:
          restartPolicy: Never
          containers:
          - name: cleanup
            image: busybox:1.36
            command: ["sh", "-c", "echo cleaning logs; sleep 5"]
EOF
kubectl create job log-cleanup-manual --from=cronjob/log-cleanup -n batch-lab

# Q14 - init container + native sidecar
kubectl apply -f - <<'EOF'
apiVersion: v1
kind: Pod
metadata:
  name: web-logger
  namespace: sidecar-lab
spec:
  nodeName: k3d-cluster-server-0
  volumes:
  - name: html
    emptyDir: {}
  - name: logs
    emptyDir: {}
  initContainers:
  - name: setup
    image: busybox:1.36
    command: ["sh", "-c", "echo 'Hello CKA' > /work/index.html"]
    volumeMounts:
    - name: html
      mountPath: /work
  - name: log-tailer
    image: busybox:1.36
    restartPolicy: Always
    command: ["sh", "-c", "tail -F /var/log/nginx/access.log"]
    volumeMounts:
    - name: logs
      mountPath: /var/log/nginx
  containers:
  - name: nginx
    image: nginx:1.25
    volumeMounts:
    - name: html
      mountPath: /usr/share/nginx/html
    - name: logs
      mountPath: /var/log/nginx
EOF

# Q15 - PV reclaim policy + label
PV=$(kubectl get pvc ledger-data -n storage-ops -o jsonpath='{.spec.volumeName}')
kubectl patch pv "$PV" -p '{"spec":{"persistentVolumeReclaimPolicy":"Retain"}}'
kubectl label pv "$PV" tier=critical --overwrite
echo "$PV" > /tmp/exam/q15/pv-name.txt

# Q16 - ServiceAccount token + kubeconfig
kubectl create sa ci-bot -n ci
kubectl apply -f - <<'EOF'
apiVersion: v1
kind: Secret
metadata:
  name: ci-bot-token
  namespace: ci
  annotations:
    kubernetes.io/service-account.name: ci-bot
type: kubernetes.io/service-account-token
EOF
kubectl create rolebinding ci-bot-view -n ci --clusterrole=view --serviceaccount=ci:ci-bot
sleep 2
F=/tmp/exam/q16/ci-bot.kubeconfig
SERVER=$(kubectl config view --minify -o jsonpath='{.clusters[0].cluster.server}')
kubectl config view --raw --minify -o jsonpath='{.clusters[0].cluster.certificate-authority-data}' | base64 -d > /tmp/exam/q16/ca.crt
TOKEN=$(kubectl get secret ci-bot-token -n ci -o jsonpath='{.data.token}' | base64 -d)
kubectl config set-cluster ckx --kubeconfig=$F --server="$SERVER" --certificate-authority=/tmp/exam/q16/ca.crt --embed-certs=true
kubectl config set-credentials ci-bot --kubeconfig=$F --token="$TOKEN"
kubectl config set-context ci-context --kubeconfig=$F --cluster=ckx --user=ci-bot --namespace=ci
kubectl config use-context ci-context --kubeconfig=$F

# Q17 - topology spread
kubectl apply -f - <<'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: spread-web
  namespace: spread-lab
spec:
  replicas: 4
  selector:
    matchLabels:
      app: spread-web
  template:
    metadata:
      labels:
        app: spread-web
    spec:
      topologySpreadConstraints:
      - maxSkew: 1
        topologyKey: topology.ckx.io/zone
        whenUnsatisfiable: DoNotSchedule
        labelSelector:
          matchLabels:
            app: spread-web
      containers:
      - name: nginx
        image: nginx:1.25
EOF

# Q18 - restore cluster DNS
kubectl patch deploy resolver -n trbl-dns --type=json -p='[
  {"op":"replace","path":"/spec/template/spec/dnsPolicy","value":"ClusterFirst"},
  {"op":"remove","path":"/spec/template/spec/dnsConfig"}]'
