#!/bin/bash
# Reference solution for cka-011 (CKA 11 · Classic Exam Tasks).

# Q1
kubectl logs bar -n web-logs | grep 'unable-to-access-website' > /tmp/exam/q1/bar-errors.log

# Q2
kubectl get nodes -o json \
  | jq '[.items[] | select(any(.status.conditions[]; .type=="Ready" and .status=="True"))
        | select([.spec.taints[]? | select(.effect=="NoSchedule")] | length == 0)] | length' \
  > /tmp/exam/q2/schedulable-nodes.txt

# Q3
kubectl get configmap coredns -n kube-system -o yaml \
  | sed 's#forward \. 192\.0\.2\.53#forward . /etc/resolv.conf#' | kubectl apply -f -
kubectl rollout restart deployment coredns -n kube-system
kubectl rollout status deployment coredns -n kube-system

# Q4 (k3s also reads extra server blocks from the optional ConfigMap coredns-custom;
# editing the Corefile of the ConfigMap coredns works the same way)
kubectl apply -f - <<'YAML'
apiVersion: v1
kind: ConfigMap
metadata:
  name: coredns-custom
  namespace: kube-system
data:
  myapp.server: |
    myapp.internal:53 {
        hosts {
            10.10.10.10 myapp.internal
        }
    }
YAML
kubectl rollout restart deployment coredns -n kube-system
kubectl rollout status deployment coredns -n kube-system

# Q5
kubectl expose deployment nginx-random -n lookup --name=nginx-random --port=80
kubectl rollout status deployment nginx-random -n lookup
kubectl run q5-svc -n lookup --image=busybox:1.36 --restart=Never --rm -i --quiet -- \
  nslookup nginx-random.lookup.svc.cluster.local > /tmp/exam/q5/nginx-random.svc
POD_IP=$(kubectl get pod -n lookup -l app=nginx-random -o jsonpath='{.items[0].status.podIP}')
kubectl run q5-pod -n lookup --image=busybox:1.36 --restart=Never --rm -i --quiet -- \
  nslookup "${POD_IP//./-}.lookup.pod.cluster.local" > /tmp/exam/q5/nginx-random.pod

# Q6
yq -i '.spec.initContainers = [{"name": "prepare", "image": "busybox:1.36",
  "command": ["sh", "-c", "touch /workdir/ready.flag"],
  "volumeMounts": [{"name": "workdir", "mountPath": "/workdir"}]}]' /tmp/exam/q6/ledger.yaml
kubectl apply -f /tmp/exam/q6/ledger.yaml

# Q7
kubectl create secret generic app-secret -n secret-lab --from-literal=password=n0t-s0-s3cret
kubectl apply -f - <<'YAML'
apiVersion: v1
kind: Pod
metadata:
  name: secret-file
  namespace: secret-lab
spec:
  containers:
  - name: nginx
    image: nginx:1.27
    volumeMounts:
    - name: secret
      mountPath: /secrets
      readOnly: true
  volumes:
  - name: secret
    secret:
      secretName: app-secret
---
apiVersion: v1
kind: Pod
metadata:
  name: secret-env
  namespace: secret-lab
spec:
  containers:
  - name: nginx
    image: nginx:1.27
    env:
    - name: APP_PASSWORD
      valueFrom:
        secretKeyRef:
          name: app-secret
          key: password
YAML

# Q8: 25% of the node's allocatable CPU and memory per Pod
CPU=$(kubectl get node k3d-cluster-agent-1 -o jsonpath='{.status.allocatable.cpu}')
MEM=$(kubectl get node k3d-cluster-agent-1 -o jsonpath='{.status.allocatable.memory}')
case "$CPU" in *m) CPU_M=${CPU%m};; *) CPU_M=$((CPU * 1000));; esac
MEM_KI=${MEM%Ki}
REQ_CPU="$((CPU_M / 4))m"; REQ_MEM="$((MEM_KI / 4 / 1024))Mi"
kubectl scale deployment cms -n blog --replicas=0
kubectl patch deployment cms -n blog --type=json -p "[
  {\"op\": \"replace\", \"path\": \"/spec/template/spec/initContainers/0/resources/requests\", \"value\": {\"cpu\": \"$REQ_CPU\", \"memory\": \"$REQ_MEM\"}},
  {\"op\": \"replace\", \"path\": \"/spec/template/spec/containers/0/resources/requests\", \"value\": {\"cpu\": \"$REQ_CPU\", \"memory\": \"$REQ_MEM\"}}]"
kubectl scale deployment cms -n blog --replicas=3

# Q9
kubectl run envdump -n oneoff --image=busybox:1.36 --restart=Never --rm -i --quiet -- env > /tmp/exam/q9/env.txt

# Q10
helm install edge /tmp/exam/q10/edge-proxy -n edge --create-namespace --set providers.kubernetesGateway.enabled=true

# Q11
kubectl apply -f - <<'YAML'
apiVersion: v1
kind: LimitRange
metadata:
  name: container-limits
  namespace: limits-lab
spec:
  limits:
  - type: Container
    defaultRequest:
      cpu: 100m
      memory: 50Mi
    default:
      cpu: 200m
      memory: 100Mi
    max:
      memory: 500Mi
YAML

# Q12
kubectl get pv -l team=storage-audit --sort-by=.spec.capacity.storage > /tmp/exam/q12/pv-by-size.txt

# Q13
kubectl apply -f - <<'YAML'
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: keep-local
provisioner: rancher.io/local-path
reclaimPolicy: Retain
volumeBindingMode: WaitForFirstConsumer
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: scratch
  namespace: retain-lab
spec:
  accessModes: ["ReadWriteOnce"]
  storageClassName: keep-local
  resources:
    requests:
      storage: 64Mi
---
apiVersion: v1
kind: Pod
metadata:
  name: writer
  namespace: retain-lab
spec:
  containers:
  - name: writer
    image: busybox:1.36
    command: ["sh", "-c", "echo 'hello from writer' > /data/hello.txt && sleep 36000"]
    volumeMounts:
    - name: data
      mountPath: /data
  volumes:
  - name: data
    persistentVolumeClaim:
      claimName: scratch
YAML
kubectl wait --for=condition=Ready pod/writer -n retain-lab --timeout=120s
kubectl delete pod writer -n retain-lab --grace-period=1
kubectl delete pvc scratch -n retain-lab

# Q14
kubectl label namespace web-app gateway-access=true
kubectl patch gateway shared-gw -n infra --type=json -p '[{"op": "replace", "path": "/spec/listeners/0/allowedRoutes",
  "value": {"namespaces": {"from": "Selector", "selector": {"matchLabels": {"gateway-access": "true"}}}}}]'
kubectl apply -f - <<'YAML'
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: web-route
  namespace: web-app
spec:
  parentRefs:
  - name: shared-gw
    namespace: infra
    sectionName: http
  hostnames:
  - web.example.com
  rules:
  - backendRefs:
    - name: web-service
      port: 80
YAML

# Q15
kubectl get pods -n audit-lab --sort-by=.metadata.name \
  -o custom-columns=POD_NAME:.metadata.name,POD_STATUS:.status.phase > /tmp/exam/q15/pod-status.txt
