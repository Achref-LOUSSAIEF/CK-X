# CKA Mock Exam 02 (CK-X edition): Solutions

> Adapted for CK-X from **Mock Exam 02** of [theplatformlab/CKA-Certified-Kubernetes-Administrator](https://github.com/theplatformlab/CKA-Certified-Kubernetes-Administrator) (MIT License, © 2026 TECH WITH MOHAMED). Questions were made concrete and auto-gradeable. Q5 (API server logs) and Q10 (`kubeadm certs renew`) need SSH access to the control plane, which CK-X does not provide, so they were replaced with tasks done through the API. Q8 uses node port `30808` because NodePorts must be in 30000-32767. Notes on the original kubeadm tasks are included below.

---

## Question 1: Service DNS

```bash
echo "web-ui.frontend.svc.cluster.local" > /tmp/exam/q1/dns-name.txt
kubectl run dns-test -n backend --image=busybox:1.36 -- sleep 3600
kubectl exec dns-test -n backend -- nslookup web-ui.frontend.svc.cluster.local > /tmp/exam/q1/nslookup.txt
```

Format: `<service>.<namespace>.svc.cluster.local`. From inside `backend`, `web-ui.frontend` also works thanks to the search domains in `/etc/resolv.conf`.

## Question 2: Rollout history and rollback

```bash
kubectl rollout history deploy/payment-service -n payments
kubectl rollout history deploy/payment-service -n payments --revision=3   # image nginx:1.25-hotfix (does not exist)
kubectl get pods -n payments                                              # ImagePullBackOff
echo 3 > /tmp/exam/q2/bad-revision.txt
kubectl rollout undo deploy/payment-service -n payments --to-revision=2
kubectl rollout status deploy/payment-service -n payments
```

`rollout undo` without `--to-revision` also goes back one revision (here to 2). After the undo, revision 2 is renumbered as revision 4.

## Question 3: Secret as environment variables

```bash
kubectl create secret generic db-creds -n app-secrets \
  --from-literal=username=dbuser --from-literal=password=secret123 --from-literal=database=appdb
```

```yaml
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
```

```bash
kubectl exec deploy/db-client -n app-secrets -- printenv DB_USERNAME
```

## Question 4: DaemonSet on the control plane

```yaml
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
```

```bash
kubectl get pods -n monitoring -o wide   # one Pod per node, including k3d-cluster-server-0
```

## Question 5: Checking the API server through the API

```bash
kubectl get --raw='/readyz?verbose' > /tmp/exam/q5/readyz.txt
kubectl get endpointslices -n default -l kubernetes.io/service-name=kubernetes
kubectl get endpointslices -n default -l kubernetes.io/service-name=kubernetes \
  -o jsonpath='{.items[0].ports[0].port}' > /tmp/exam/q5/apiserver-port.txt      # 6443
```

On a kubeadm control-plane node you would also use `crictl logs <kube-apiserver container>`, `ss -tlnp | grep 6443`, and `kubectl get --raw /metrics | grep apiserver_request_total`.

## Question 6: ConfigMap updates

```bash
kubectl patch cm app-config -n config-reload --type=merge -p '{"data":{"APP_MODE":"production"}}'
kubectl edit deploy config-app -n config-reload     # add the volume below
kubectl rollout status deploy/config-app -n config-reload
```

```yaml
      containers:
      - name: app
        volumeMounts:
        - name: config
          mountPath: /etc/app        # no subPath
      volumes:
      - name: config
        configMap:
          name: app-config
```

Environment variables are read once at container start, so Pods need a restart (`kubectl rollout restart deploy/config-app -n config-reload`; editing the template already triggers one). Files from a ConfigMap volume are refreshed by the kubelet within about a minute, unless mounted with `subPath`.

## Question 7: PriorityClasses

```bash
kubectl create priorityclass critical --value=1000 --description="critical workloads"
kubectl create priorityclass standard --value=100 --description="standard workloads"
kubectl run critical-pod-1 -n priority-lab --image=nginx:1.25 --overrides='{"spec":{"priorityClassName":"critical"}}'
kubectl run critical-pod-2 -n priority-lab --image=nginx:1.25 --overrides='{"spec":{"priorityClassName":"critical"}}'
kubectl run standard-pod   -n priority-lab --image=nginx:1.25 --overrides='{"spec":{"priorityClassName":"standard"}}'
```

With the default `preemptionPolicy: PreemptLowerPriority`, a pending higher-priority Pod can evict lower-priority Pods to make room. `preemptionPolicy: Never` gives queue priority without evicting anything. Kubelet node-pressure eviction also takes priority into account.

## Question 8: NodePort Service

```yaml
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
  - port: 8080          # Service (ClusterIP) port
    targetPort: 3000    # container port
    nodePort: 30808     # opened on every node
```

```bash
NODEIP=$(kubectl get nodes -o jsonpath='{.items[0].status.addresses[?(@.type=="InternalIP")].address}')
kubectl exec probe -n legacy -- wget -qO- http://$NODEIP:30808
```

## Question 9: Suspended CronJob

```yaml
apiVersion: batch/v1
kind: CronJob
metadata:
  name: backup-job
  namespace: backups
spec:
  schedule: "0 2 * * *"
  suspend: true
  successfulJobsHistoryLimit: 3
  jobTemplate:
    spec:
      template:
        spec:
          restartPolicy: OnFailure
          containers:
          - name: backup
            image: busybox:1.36
            command: ["sh", "-c", "echo backup done"]
```

Resume later with `kubectl patch cronjob backup-job -n backups -p '{"spec":{"suspend":false}}'`.

## Question 10: Certificates with the CSR API

```bash
cat <<EOF | kubectl apply -f -
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
kubectl get csr john -o jsonpath='{.status.certificate}' | base64 -d > /tmp/exam/q10/john.crt
openssl x509 -in /tmp/exam/q10/john.crt -noout -subject -enddate
```

On a kubeadm cluster, control-plane certificate rotation is `kubeadm certs check-expiration`, then `kubeadm certs renew all`, then restarting the static Pods (move the manifests out of `/etc/kubernetes/manifests` and back) so they load the new certificates.

## Question 11: PodDisruptionBudget

```bash
kubectl create pdb app-pdb -n pdb-lab --selector=app=web-app --max-unavailable=2
kubectl get pdb app-pdb -n pdb-lab     # ALLOWED DISRUPTIONS: 2
```

`kubectl drain` uses the Eviction API, which refuses evictions that would break the budget, so a drain proceeds at most 2 Pods at a time.

## Question 12: Custom resources

```bash
kubectl get crd | grep -i database                       # databases.stable.example.com
kubectl api-resources | grep -i database                 # group/version stable.example.com/v1, short name db
kubectl explain database.spec
```

```yaml
apiVersion: stable.example.com/v1
kind: Database
metadata:
  name: prod-db
  namespace: crd-db
spec:
  engine: postgres
  version: "16"
  storageGB: 20
```

```bash
kubectl delete database legacy-db -n crd-db
```

## Question 13: Running a root Pod under Pod Security Admission

```bash
kubectl create namespace privileged-apps
kubectl label namespace privileged-apps pod-security.kubernetes.io/enforce=baseline
kubectl run privileged-pod -n privileged-apps --image=nginx:1.25 \
  --overrides='{"spec":{"securityContext":{"runAsUser":0}}}'
```

Pod Security Admission works per namespace; there is no per-Pod exemption label. `baseline` allows running as root but still blocks privileged containers and host namespaces. (Cluster-wide exemptions by user, RuntimeClass or namespace exist in the API server's admission configuration file.)

## Question 14: Dynamic provisioning

```yaml
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
```

With `WaitForFirstConsumer`, the PVC stays `Pending` until the Pod is scheduled; then the provisioner creates the PV on that node.

## Question 15: Namespace quota and limits

```bash
kubectl create quota batch-jobs-quota -n batch-jobs --hard=limits.cpu=10,limits.memory=20Gi
```

```yaml
apiVersion: v1
kind: LimitRange
metadata:
  name: batch-jobs-limits
  namespace: batch-jobs
spec:
  limits:
  - type: Container
    min: {cpu: 500m, memory: 256Mi}
    max: {cpu: "4", memory: 8Gi}
    default: {cpu: "1", memory: 1Gi}
    defaultRequest: {cpu: 500m, memory: 256Mi}
```

Once a quota covers `limits.cpu`, every Pod must declare a CPU limit; the LimitRange `default` fills it in for Pods that don't. A container asking for 6 CPUs is rejected by the `max`.

---

## License of the original questions

```text
MIT License

Copyright (c) 2026 TECH WITH MOHAMED

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```
