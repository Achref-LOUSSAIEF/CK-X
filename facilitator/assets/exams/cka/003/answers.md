# CKA Practice Lab 3 – Troubleshooting & Cluster Operations: Solutions

Troubleshooting is the largest domain of the CKA (30%). For every "broken" task, the workflow is the same:

```bash
kubectl get pods -n <ns>                 # what state are the Pods in?
kubectl describe pod <pod> -n <ns>       # Events at the bottom tell you why
kubectl logs <pod> -n <ns> [-c <ctr>] [--previous]
kubectl get events -n <ns> --sort-by=.lastTimestamp
```

---

## Question 1: Deployment never becomes Ready

Two faults: the image tag is misspelled (`nginx:1.25-alpne` → `ErrImagePull`) and the readiness probe checks port `8080` while nginx listens on `80`.

```bash
kubectl describe pod -n trbl-deploy -l app=payment-api   # ErrImagePull / Readiness probe failed
kubectl set image deploy/payment-api api=nginx:1.25-alpine -n trbl-deploy
kubectl edit deploy payment-api -n trbl-deploy           # readinessProbe.httpGet.port: 80
kubectl rollout status deploy/payment-api -n trbl-deploy
```

Fixing only the image leaves Pods `Running` but `0/1 Ready`, so always confirm the READY column.

## Question 2: Service without endpoints

```bash
kubectl get endpointslices -n trbl-svc -l kubernetes.io/service-name=web-svc   # no endpoints
kubectl get pods -n trbl-svc --show-labels                                      # app=web-frontend
```

The selector (`app=web-front`) does not match the Pods and `targetPort` is `8080`.

```bash
kubectl patch svc web-svc -n trbl-svc --type=merge \
  -p '{"spec":{"selector":{"app":"web-frontend"},"ports":[{"port":80,"targetPort":80,"protocol":"TCP"}]}}'
kubectl exec client -n trbl-svc -- wget -qO- -T 3 http://web-svc
```

## Question 3: Pods stuck in Pending

`kubectl describe pod` shows `0/3 nodes are available: ... didn't match Pod's node affinity/selector, ... Insufficient cpu`.

```bash
kubectl patch deploy batch-processor -n trbl-sched --type=json -p='[
  {"op":"remove","path":"/spec/template/spec/nodeSelector"},
  {"op":"replace","path":"/spec/template/spec/containers/0/resources/requests/cpu","value":"100m"}]'
```

## Question 4: CreateContainerConfigError

Events show `secret "order-db" not found`, then `couldn't find key queue_name in ConfigMap trbl-config/order-config` (the ConfigMap has `queue-name` with a dash).

```bash
kubectl create secret generic order-db -n trbl-config --from-literal=password='Sup3rS3cret!'
kubectl patch cm order-config -n trbl-config --type=merge -p '{"data":{"queue_name":"orders"}}'
```

Kubelet retries automatically, so the Pod starts without restarting the Deployment. Single-quote the password so the shell does not interpret `!`.

## Question 5: Container logs

```bash
kubectl logs audit-app -n logging -c app | grep ERROR > /tmp/exam/q5/errors.log
kubectl get pod audit-app -n logging -o jsonpath='{.spec.nodeName}' > /tmp/exam/q5/node.txt
```

Without `-c app`, kubectl either errors or (with `--all-containers`) mixes in the `shipper` lines, which also contain `ERROR`.

## Question 6: Highest CPU consumer

```bash
kubectl top pod -n metrics-lab -l app=analytics --sort-by=cpu
kubectl top pod -n metrics-lab -l app=analytics --sort-by=cpu --no-headers | head -1 | awk '{print $1}' > /tmp/exam/q6/top-pod.txt
```

Answer: `analytics-2` (it runs a busy loop).

## Question 7: Node maintenance

```bash
kubectl drain k3d-cluster-agent-0 --ignore-daemonsets --delete-emptydir-data
kubectl get pods -n maintenance -o wide
```

`drain` cordons the node first, then evicts. `--ignore-daemonsets` is required because DaemonSet Pods cannot be evicted (they would be recreated on the same node). Afterwards `kubectl uncordon k3d-cluster-agent-0` would bring it back — don't do that here.

## Question 8: ClusterRole vs Role

```bash
kubectl create clusterrole node-viewer --verb=get,list,watch --resource=nodes,persistentvolumes
kubectl create clusterrolebinding jane-node-viewer --clusterrole=node-viewer --user=jane

kubectl create role deploy-manager -n rbac-lab --verb=get,list,create,update,patch,delete --resource=deployments
kubectl create rolebinding developers-deploy-manager -n rbac-lab --role=deploy-manager --group=developers

kubectl auth can-i list nodes --as jane                                              # yes
kubectl auth can-i create deployments -n rbac-lab --as bob --as-group developers     # yes
kubectl auth can-i create deployments -n default  --as bob --as-group developers     # no
```

Nodes and PersistentVolumes are cluster-scoped, so they need a ClusterRole + ClusterRoleBinding.

## Question 9: CustomResourceDefinition

```yaml
apiVersion: apiextensions.k8s.io/v1
kind: CustomResourceDefinition
metadata:
  name: backups.ops.example.com      # must be <plural>.<group>
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
---
apiVersion: ops.example.com/v1
kind: Backup
metadata:
  name: nightly
  namespace: crd-lab
spec:
  schedule: "0 2 * * *"
  retentionDays: 7
```

`kubectl get crd` / `kubectl api-resources | grep backup` confirm the new type; `kubectl explain backup.spec` works thanks to the schema.

## Question 10: Services and Ingress

```bash
kubectl expose deploy shop -n ingress-lab --name=shop-svc --port=80 --target-port=80
kubectl expose deploy api  -n ingress-lab --name=api-svc  --port=8080 --target-port=80
kubectl create ingress shop-ingress -n ingress-lab --class=traefik \
  --rule="shop.example.local/api*=api-svc:8080" \
  --rule="shop.example.local/*=shop-svc:80"
```

A trailing `*` in `--rule` creates a `Prefix` path; without it the path is `Exact`.

## Question 11: NetworkPolicies

```yaml
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
    - namespaceSelector:          # one list item containing BOTH selectors = AND
        matchLabels:
          team: backend
      podSelector:
        matchLabels:
          role: api
    ports:
    - protocol: TCP
      port: 80
```

The most common mistake is putting a `-` in front of `podSelector`, which creates two peers (OR) and lets `np-other/api` and `np-backend/worker` in.

```bash
kubectl exec -n np-backend api    -- wget -qO- -T 3 http://db.np-db.svc.cluster.local   # works
kubectl exec -n np-backend worker -- wget -qO- -T 3 http://db.np-db.svc.cluster.local   # times out
```

## Question 12: DaemonSet

```yaml
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
      - operator: Exists          # run even on tainted (e.g. control-plane) nodes
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
```

Tip: generate a Deployment with `kubectl create deploy ... --dry-run=client -o yaml`, change `kind` to `DaemonSet` and delete `replicas`, `strategy` and `status`.

## Question 13: CronJob and manual Job

```bash
kubectl create cronjob log-cleanup -n batch-lab --image=busybox:1.36 --schedule="*/15 * * * *" \
  --dry-run=client -o yaml -- sh -c 'echo cleaning logs; sleep 5' > cj.yaml
```

Edit `cj.yaml` to add the remaining fields:

```yaml
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
          - name: cleanup            # rename from log-cleanup
            image: busybox:1.36
            command: ["sh", "-c", "echo cleaning logs; sleep 5"]
```

```bash
kubectl apply -f cj.yaml
kubectl create job log-cleanup-manual --from=cronjob/log-cleanup -n batch-lab
kubectl wait --for=condition=complete job/log-cleanup-manual -n batch-lab
```

## Question 14: Init container and native sidecar

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: web-logger
  namespace: sidecar-lab
spec:
  nodeName: k3d-cluster-server-0        # or nodeSelector kubernetes.io/hostname
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
    restartPolicy: Always                # this is what makes it a native sidecar
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
```

```bash
kubectl exec web-logger -n sidecar-lab -c nginx -- curl -s localhost
kubectl logs web-logger -n sidecar-lab -c log-tailer
```

Mounting an `emptyDir` over `/var/log/nginx` replaces the image's symlink to stdout, so nginx writes a real file the sidecar can tail.

## Question 15: PersistentVolume reclaim policy

```bash
PV=$(kubectl get pvc ledger-data -n storage-ops -o jsonpath='{.spec.volumeName}')
kubectl patch pv "$PV" -p '{"spec":{"persistentVolumeReclaimPolicy":"Retain"}}'
kubectl label pv "$PV" tier=critical
echo "$PV" > /tmp/exam/q15/pv-name.txt
kubectl get pv "$PV" --show-labels
```

The reclaim policy lives on the PV, not on the PVC; dynamically provisioned PVs inherit the StorageClass's policy (`Delete` by default).

## Question 16: ServiceAccount token and kubeconfig

```bash
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

F=/tmp/exam/q16/ci-bot.kubeconfig
SERVER=$(kubectl config view --minify -o jsonpath='{.clusters[0].cluster.server}')
kubectl config view --raw --minify -o jsonpath='{.clusters[0].cluster.certificate-authority-data}' | base64 -d > /tmp/exam/q16/ca.crt
TOKEN=$(kubectl get secret ci-bot-token -n ci -o jsonpath='{.data.token}' | base64 -d)

kubectl config set-cluster ckx --kubeconfig=$F --server="$SERVER" --certificate-authority=/tmp/exam/q16/ca.crt --embed-certs=true
kubectl config set-credentials ci-bot --kubeconfig=$F --token="$TOKEN"
kubectl config set-context ci-context --kubeconfig=$F --cluster=ckx --user=ci-bot --namespace=ci
kubectl config use-context ci-context --kubeconfig=$F

kubectl --kubeconfig $F get pods            # works
kubectl --kubeconfig $F auth can-i create deployments   # no
```

Since Kubernetes 1.24, ServiceAccounts no longer get a token Secret automatically; `kubectl create token ci-bot` gives a short-lived token, while the annotated Secret gives a long-lived one.

## Question 17: Topology spread constraints

```yaml
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
```

With `DoNotSchedule`, nodes that do not carry the topology key (here `k3d-cluster-agent-0`) are not eligible, so the 4 Pods land 2 + 2 on the two zones.

## Question 18: Broken Pod DNS

```bash
kubectl get deploy resolver -n trbl-dns -o yaml | grep -A4 dns     # dnsPolicy: None + bogus nameserver
kubectl patch deploy resolver -n trbl-dns --type=json -p='[
  {"op":"replace","path":"/spec/template/spec/dnsPolicy","value":"ClusterFirst"},
  {"op":"remove","path":"/spec/template/spec/dnsConfig"}]'
kubectl exec deploy/resolver -n trbl-dns -- nslookup kubernetes.default.svc.cluster.local
```

`ClusterFirst` (the default) makes kubelet write the CoreDNS Service IP and the `<ns>.svc.cluster.local` search domains into the Pod's `/etc/resolv.conf`.
