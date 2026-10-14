#!/bin/bash
# Reference solution for cka-007 (CKA 7 · Exam Simulation II).

# Q1
kubectl get nodes -o jsonpath='{range .items[*]}{.metadata.name} {.status.addresses[?(@.type=="InternalIP")].address}{"\n"}{end}' | sort > /tmp/exam/q1/nodes.txt

# Q2
kubectl apply -f - <<'EOF'
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-dns
  namespace: sales
spec:
  podSelector: {}
  policyTypes: ["Egress"]
  egress:
  - to:
    - namespaceSelector:
        matchLabels:
          kubernetes.io/metadata.name: kube-system
      podSelector:
        matchLabels:
          k8s-app: kube-dns
    ports:
    - protocol: UDP
      port: 53
    - protocol: TCP
      port: 53
EOF

# Q3
kubectl describe rs -n quota-lab -l app=inventory | tail -5
kubectl set resources deployment inventory -n quota-lab \
  --requests=cpu=100m,memory=64Mi --limits=cpu=200m,memory=128Mi

# Q4
kubectl apply -f - <<'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: shop-v2
  namespace: shop
spec:
  replicas: 1
  selector:
    matchLabels:
      app: shop
      version: v2
  template:
    metadata:
      labels:
        app: shop
        version: v2
    spec:
      containers:
      - name: web
        image: nginx:1.27
EOF

# Q5
kubectl apply -f - <<'EOF'
apiVersion: v1
kind: Service
metadata:
  name: legacy-db
  namespace: integrations
spec:
  ports:
  - name: postgres
    port: 5432
    targetPort: 5432
---
apiVersion: discovery.k8s.io/v1
kind: EndpointSlice
metadata:
  name: legacy-db-1
  namespace: integrations
  labels:
    kubernetes.io/service-name: legacy-db
addressType: IPv4
ports:
- name: postgres
  port: 5432
  protocol: TCP
endpoints:
- addresses: ["10.0.0.50"]
EOF

# Q6
kubectl apply -f - <<'EOF'
apiVersion: v1
kind: Pod
metadata:
  name: vault-agent
  namespace: vault
spec:
  containers:
  - name: agent
    image: busybox:1.36
    command: ["sleep", "3600"]
    volumeMounts:
    - name: token
      mountPath: /etc/app
      readOnly: true
  volumes:
  - name: token
    secret:
      secretName: app-secrets
      items:
      - key: api-token
        path: token
        mode: 0400
EOF

# Q7
kubectl apply -f - <<'EOF'
apiVersion: batch/v1
kind: Job
metadata:
  name: batch-import
  namespace: batch
spec:
  completions: 6
  parallelism: 2
  backoffLimit: 3
  ttlSecondsAfterFinished: 10800
  template:
    spec:
      restartPolicy: Never
      containers:
      - name: import
        image: busybox:1.36
        command: ["sh", "-c", "echo importing; sleep 2"]
EOF

# Q8
kubectl apply -f - <<'EOF'
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: monitoring-aggregate
aggregationRule:
  clusterRoleSelectors:
  - matchLabels:
      rbac.ckx.io/aggregate-to-monitoring: "true"
rules: []
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: monitoring-pods
  labels:
    rbac.ckx.io/aggregate-to-monitoring: "true"
rules:
- apiGroups: [""]
  resources: ["pods", "services"]
  verbs: ["get", "list", "watch"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: monitoring-nodes
  labels:
    rbac.ckx.io/aggregate-to-monitoring: "true"
rules:
- apiGroups: [""]
  resources: ["nodes"]
  verbs: ["get", "list"]
EOF
kubectl create clusterrolebinding prometheus-monitoring --clusterrole=monitoring-aggregate --serviceaccount=monitoring:prometheus

# Q9
kubectl apply -f - <<'EOF'
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: store
  namespace: canary
spec:
  parentRefs:
  - name: edge
  hostnames: ["store.example.local"]
  rules:
  - backendRefs:
    - name: store-v1
      port: 80
      weight: 90
    - name: store-v2
      port: 80
      weight: 10
EOF

# Q10
mkdir -p /tmp/exam/q10/overlays/staging
cat > /tmp/exam/q10/overlays/staging/kustomization.yaml <<'EOF'
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
- ../../base
namespace: staging
namePrefix: staging-
labels:
- pairs:
    env: staging
images:
- name: nginx
  newTag: "1.27"
replicas:
- name: api
  count: 2
EOF
kubectl apply -k /tmp/exam/q10/overlays/staging

# Q11
helm install webapp /tmp/exam/q11/webapp -n helm-apps --create-namespace -f /tmp/exam/q11/values-prod.yaml
helm upgrade webapp /tmp/exam/q11/webapp -n helm-apps --reuse-values --set image.tag=1.27
helm rollback webapp 1 -n helm-apps

# Q12
kubectl patch pdb ledger-pdb -n ledger --type=json \
  -p='[{"op":"remove","path":"/spec/minAvailable"},{"op":"add","path":"/spec/maxUnavailable","value":1}]'
kubectl drain k3d-cluster-agent-0 --ignore-daemonsets --delete-emptydir-data --timeout=120s

# Q13
kubectl logs -n reporting deploy/report-gen --previous 2>/dev/null | grep -i "not found" > /tmp/exam/q13/error.txt \
  || kubectl logs -n reporting deploy/report-gen | grep -i "not found" > /tmp/exam/q13/error.txt
kubectl patch deployment report-gen -n reporting --type=json \
  -p='[{"op":"replace","path":"/spec/template/spec/containers/0/command","value":["sh","-c","echo starting report generator; sleep 3600"]}]'

# Q14 - storageClassName of a PVC is immutable: recreate the PVC and the Pod
kubectl get pod archive -n archive -o yaml > /tmp/archive-pod.yaml
kubectl delete pod archive -n archive --wait=false
kubectl delete pvc archive-data -n archive
kubectl apply -f - <<'EOF'
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: archive-data
  namespace: archive
spec:
  storageClassName: local-path
  accessModes: ["ReadWriteOnce"]
  resources:
    requests:
      storage: 1Gi
EOF
kubectl apply -f - <<'EOF'
apiVersion: v1
kind: Pod
metadata:
  name: archive
  namespace: archive
spec:
  containers:
  - name: archive
    image: busybox:1.36
    command: ["sh", "-c", "while true; do date >> /data/heartbeat; sleep 30; done"]
    volumeMounts:
    - name: data
      mountPath: /data
  volumes:
  - name: data
    persistentVolumeClaim:
      claimName: archive-data
EOF

# Q15
kubectl apply -f - <<'EOF'
apiVersion: admissionregistration.k8s.io/v1
kind: ValidatingAdmissionPolicy
metadata:
  name: require-two-replicas
spec:
  failurePolicy: Fail
  matchConstraints:
    resourceRules:
    - apiGroups: ["apps"]
      apiVersions: ["v1"]
      operations: ["CREATE", "UPDATE"]
      resources: ["deployments"]
  validations:
  - expression: "object.spec.replicas >= 2"
    message: "production Deployments need at least 2 replicas"
---
apiVersion: admissionregistration.k8s.io/v1
kind: ValidatingAdmissionPolicyBinding
metadata:
  name: require-two-replicas-binding
spec:
  policyName: require-two-replicas
  validationActions: ["Deny"]
  matchResources:
    namespaceSelector:
      matchLabels:
        env: prod
EOF

# Q16
kubectl get pods -n observability --sort-by=.metadata.creationTimestamp -o custom-columns=NAME:.metadata.name --no-headers > /tmp/exam/q16/pods-by-age.txt
