#!/bin/bash
# Reference solution for cka-008 (CKA 8 · Exam Simulation III).

# Q1
kubectl patch statefulset web -n stateful --type=merge \
  -p '{"spec":{"updateStrategy":{"type":"RollingUpdate","rollingUpdate":{"partition":2}}}}'
kubectl set image statefulset/web -n stateful nginx=nginx:1.27

# Q2
kubectl apply -f - <<'EOF'
apiVersion: v1
kind: ConfigMap
metadata:
  name: frontend-config-v2
  namespace: frontend
immutable: true
data:
  LOG_LEVEL: debug
  THEME: dark
EOF
kubectl patch deployment frontend -n frontend --type=json \
  -p='[{"op":"replace","path":"/spec/template/spec/containers/0/envFrom/0/configMapRef/name","value":"frontend-config-v2"}]'

# Q3
kubectl apply -f - <<'EOF'
apiVersion: v1
kind: Pod
metadata:
  name: meta-reporter
  namespace: telemetry
spec:
  containers:
  - name: reporter
    image: busybox:1.36
    command: ["sh", "-c", "env; sleep 3600"]
    resources:
      limits:
        memory: 64Mi
    env:
    - name: POD_NAME
      valueFrom:
        fieldRef:
          fieldPath: metadata.name
    - name: POD_IP
      valueFrom:
        fieldRef:
          fieldPath: status.podIP
    - name: NODE_NAME
      valueFrom:
        fieldRef:
          fieldPath: spec.nodeName
    - name: MEM_LIMIT_MI
      valueFrom:
        resourceFieldRef:
          containerName: reporter
          resource: limits.memory
          divisor: 1Mi
EOF

# Q4
kubectl patch deployment api -n startup --type=json \
  -p='[{"op":"replace","path":"/spec/template/spec/initContainers/0/command","value":["sh","-c","until nslookup database.startup.svc.cluster.local; do echo waiting for db; sleep 2; done"]}]'

# Q5
kubectl create service externalname provider -n payments --external-name=api.payments-provider.example.com

# Q6
kubectl apply -f - <<'EOF'
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: crawler-egress
  namespace: crawler
spec:
  podSelector:
    matchLabels:
      app: crawler
  policyTypes: ["Egress"]
  egress:
  - to:
    - ipBlock:
        cidr: 10.20.0.0/16
        except: ["10.20.5.0/24"]
    ports:
    - protocol: TCP
      port: 8000
      endPort: 8100
  - ports:
    - protocol: UDP
      port: 53
    - protocol: TCP
      port: 53
EOF

# Q7
kubectl apply -f - <<'EOF'
apiVersion: v1
kind: Service
metadata:
  name: cache-peers
  namespace: cache
spec:
  clusterIP: None
  selector:
    app: cache
  ports:
  - name: redis
    port: 6379
    targetPort: 6379
EOF
echo cache-peers.cache.svc.cluster.local > /tmp/exam/q7/fqdn.txt

# Q8
kubectl apply -f - <<'EOF'
apiVersion: v1
kind: ServiceAccount
metadata:
  name: builder
  namespace: ci
automountServiceAccountToken: false
---
apiVersion: v1
kind: Pod
metadata:
  name: builder
  namespace: ci
spec:
  serviceAccountName: builder
  containers:
  - name: builder
    image: busybox:1.36
    command: ["sleep", "3600"]
    volumeMounts:
    - name: vault-token
      mountPath: /var/run/secrets/vault
      readOnly: true
  volumes:
  - name: vault-token
    projected:
      sources:
      - serviceAccountToken:
          audience: vault
          expirationSeconds: 3600
          path: token
EOF

# Q9
kubectl create role app-settings-editor -n config --verb=get,update,patch --resource=configmaps --resource-name=app-settings
kubectl create rolebinding jane-app-settings -n config --role=app-settings-editor --user=jane

# Q10
kubectl apply -f - <<'EOF'
apiVersion: v1
kind: Pod
metadata:
  name: hardened
  namespace: secure
spec:
  securityContext:
    runAsUser: 1000
    runAsGroup: 3000
    fsGroup: 2000
  containers:
  - name: app
    image: busybox:1.36
    command: ["sh", "-c", "while true; do date >> /work/log; sleep 10; done"]
    securityContext:
      readOnlyRootFilesystem: true
      allowPrivilegeEscalation: false
      capabilities:
        drop: ["ALL"]
    volumeMounts:
    - name: work
      mountPath: /work
  volumes:
  - name: work
    emptyDir: {}
EOF

# Q11
kubectl patch deployment edge-cache -n edge --type=merge -p '{"spec":{"template":{"spec":{"tolerations":[
  {"key":"node.kubernetes.io/unreachable","operator":"Exists","effect":"NoExecute","tolerationSeconds":30},
  {"key":"node.kubernetes.io/not-ready","operator":"Exists","effect":"NoExecute","tolerationSeconds":30}]}}}}'

# Q12
kubectl apply -f - <<'EOF'
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: local-ssd
provisioner: kubernetes.io/no-provisioner
volumeBindingMode: WaitForFirstConsumer
---
apiVersion: v1
kind: PersistentVolume
metadata:
  name: ssd-pv-1
spec:
  capacity:
    storage: 2Gi
  accessModes: ["ReadWriteOnce"]
  persistentVolumeReclaimPolicy: Retain
  storageClassName: local-ssd
  local:
    path: /mnt/disks/ssd1
  nodeAffinity:
    required:
      nodeSelectorTerms:
      - matchExpressions:
        - key: kubernetes.io/hostname
          operator: In
          values: ["k3d-cluster-agent-1"]
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: ssd-claim
  namespace: localdisk
spec:
  storageClassName: local-ssd
  accessModes: ["ReadWriteOnce"]
  resources:
    requests:
      storage: 2Gi
EOF

# Q13
kubectl rollout history deployment checkout -n checkout
kubectl rollout history deployment checkout -n checkout --revision=1 | grep Image
echo 1 > /tmp/exam/q13/revision.txt
kubectl rollout undo deployment checkout -n checkout --to-revision=1

# Q14
kubectl get pods -n inventory -o jsonpath='{range .items[*]}{range .spec.initContainers[*]}{.image}{"\n"}{end}{range .spec.containers[*]}{.image}{"\n"}{end}{end}' \
  | grep -v '^$' | sort -u > /tmp/exam/q14/images.txt

# Q15
kubectl apply -f - <<'EOF'
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: api
  namespace: gw-lab
spec:
  parentRefs:
  - name: public
  hostnames: ["api.example.local"]
  rules:
  - matches:
    - headers:
      - name: x-channel
        value: beta
    backendRefs:
    - name: api-beta
      port: 8080
  - backendRefs:
    - name: api-stable
      port: 8080
EOF

# Q16
kubectl patch service orders -n orders --type=merge \
  -p '{"spec":{"selector":{"app":"orders","tier":"backend"},"ports":[{"port":80,"targetPort":80}]}}'
