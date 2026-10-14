# CKA Final Exam Simulation: Solutions

> Original CK-X exam. The list of topics was inspired by [markdjones82/CKA-PREP-2025-v2](https://github.com/markdjones82/CKA-PREP-2025-v2); all scenarios, wording, setup and grading were written for CK-X. Topics that need SSH access to a node (CNI install, cri-dockerd, etcd / kube-apiserver repair) are not part of this exam; practise them on a kubeadm cluster.

---

## Question 1: Reuse a Released PersistentVolume

A PV with `Retain` keeps its `claimRef` to the deleted PVC, so it stays `Released` and no new claim can bind to it. Remove the `claimRef` (do **not** delete the PV — that is where the data lives):

```bash
kubectl get pv orders-pv                      # STATUS Released, CLAIM orders/orders-old
kubectl patch pv orders-pv --type=json -p='[{"op":"remove","path":"/spec/claimRef"}]'
kubectl get pv orders-pv                      # STATUS Available
```

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: orders-data
  namespace: orders
spec:
  storageClassName: manual
  volumeName: orders-pv        # optional, makes the binding explicit
  accessModes: ["ReadWriteOnce"]
  resources:
    requests:
      storage: 500Mi
```

Then edit `/tmp/exam/q1/orders-db.yaml`:

```yaml
      containers:
      - name: mariadb
        ...
        volumeMounts:
        - name: data
          mountPath: /var/lib/mysql
      volumes:
      - name: data
        persistentVolumeClaim:
          claimName: orders-data
```

```bash
kubectl apply -f /tmp/exam/q1/orders-db.yaml
kubectl rollout status deploy/orders-db -n orders
```

## Question 2: Render a Helm chart without CRDs

```bash
helm repo add argo https://argoproj.github.io/argo-helm
helm repo update argo
kubectl create namespace argocd
helm show values argo/argo-cd --version 7.7.3 | grep -A3 '^crds:'   # crds.install: true
helm template argocd argo/argo-cd --version 7.7.3 -n argocd \
  --set crds.install=false > /tmp/exam/q2/argocd.yaml
grep -c 'kind: CustomResourceDefinition' /tmp/exam/q2/argocd.yaml     # 0
```

`--skip-crds` only skips files in the chart's `crds/` folder. The argo-cd chart ships its CRDs as normal templates behind the value `crds.install`, which is why you must check the chart's values. `helm template` renders locally and installs nothing.

## Question 3: Native sidecar on an existing Deployment

```bash
kubectl edit deploy invoice-api -n billing
```

```yaml
    spec:
      initContainers:
      - name: log-shipper
        image: busybox:1.36
        restartPolicy: Always          # makes it a native sidecar
        command: ["sh", "-c", "tail -F /var/log/invoice/app.log"]
        volumeMounts:
        - name: logs
          mountPath: /var/log/invoice
      containers:
      - name: api
        ...
        volumeMounts:
        - name: logs
          mountPath: /var/log/invoice
      volumes:
      - name: logs
        emptyDir: {}
```

```bash
kubectl logs deploy/invoice-api -n billing -c log-shipper
```

## Question 4: HPA with scaling behavior

```bash
kubectl autoscale deploy checkout -n checkout --name=checkout-hpa --min=2 --max=8 --cpu=60% \
  --dry-run=client -o yaml > hpa.yaml      # older kubectl: --cpu-percent=60
```

Add the behavior and apply:

```yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: checkout-hpa
  namespace: checkout
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: checkout
  minReplicas: 2
  maxReplicas: 8
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 60
  behavior:
    scaleDown:
      stabilizationWindowSeconds: 120
```

## Question 5: CRDs and `kubectl explain`

```bash
kubectl get crd | grep cert-manager
kubectl get crd -o name | sed 's#.*/##' | grep 'cert-manager.io$' > /tmp/exam/q5/crds.txt
kubectl explain certificate.spec.subject > /tmp/exam/q5/subject.txt
```

`kubectl explain` works for custom resources too, as long as the CRD has a schema. Add `--recursive` to see every nested field at once.

## Question 6: PriorityClass relative to the existing ones

```bash
kubectl get priorityclass --sort-by=.value     # ignore system-* ; highest is critical-batch = 500000
kubectl create priorityclass urgent --value=499999 --description="one below critical-batch"
kubectl patch deploy queue-worker -n jobs -p '{"spec":{"template":{"spec":{"priorityClassName":"urgent"}}}}'
kubectl get pods -n jobs -o custom-columns=NAME:.metadata.name,PRIO:.spec.priority
```

A Pod's priority is resolved when it is created, so changing the template triggers a rollout and the new Pods get `499999`.

## Question 7: Dedicated node (taint + selector)

```bash
kubectl taint node k3d-cluster-agent-1 dedicated=ml:NoSchedule
kubectl label node k3d-cluster-agent-1 dedicated=ml
```

```yaml
    spec:
      nodeSelector:
        dedicated: ml              # attracts the Pods to the node
      tolerations:                 # allows them onto the tainted node
      - key: dedicated
        operator: Equal
        value: ml
        effect: NoSchedule
```

A toleration only *allows* scheduling on the tainted node; without the selector the Pods could land anywhere. You need both.

## Question 8: Ingress to Gateway API

```yaml
apiVersion: gateway.networking.k8s.io/v1
kind: Gateway
metadata:
  name: web-gateway
  namespace: web
spec:
  gatewayClassName: ckx-gateway
  listeners:
  - name: https
    port: 443
    protocol: HTTPS
    hostname: web.example.local
    tls:
      mode: Terminate
      certificateRefs:
      - kind: Secret
        name: web-tls
---
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: web-route
  namespace: web
spec:
  parentRefs:
  - name: web-gateway
  hostnames: ["web.example.local"]
  rules:
  - matches:
    - path:
        type: PathPrefix
        value: /
    backendRefs:
    - name: web
      port: 80
```

```bash
kubectl delete ingress web -n web
```

## Question 9: Broken Ingress

```bash
kubectl describe ingress store -n store          # backend store-api:80
kubectl get svc store-api -n store               # the Service listens on 8080 (named port http)
kubectl get endpointslices -n store              # endpoints exist, so the Service is fine
```

Two faults: `pathType: Exact` only matches `/api` itself (not `/api/orders`), and the backend points to port `80`, which the Service doesn't expose.

```bash
kubectl patch ingress store -n store --type=json -p='[
  {"op":"replace","path":"/spec/rules/0/http/paths/0/pathType","value":"Prefix"},
  {"op":"replace","path":"/spec/rules/0/http/paths/0/backend/service/port/number","value":8080}]'
```

## Question 10: Least-permissive NetworkPolicy

| File | What it allows | Verdict |
|---|---|---|
| `policy-1.yaml` | All ingress to every Pod in `backend` | Far too permissive |
| `policy-2.yaml` | `app=frontend` Pods **in the `backend` namespace** | Doesn't work: a `podSelector` alone only matches the policy's own namespace |
| `policy-3.yaml` | `app=frontend` Pods in namespace `frontend`, TCP 80 | **Correct and least permissive** |
| `policy-4.yaml` | Any Pod in namespace `frontend`, any port | Works but too permissive |

```bash
kubectl apply -f /tmp/exam/q10/policy-3.yaml
```

In policy-3, `namespaceSelector` and `podSelector` are in the **same** list item, so both must match (AND).

## Question 11: Default StorageClass

```yaml
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: fast-retain
  annotations:
    storageclass.kubernetes.io/is-default-class: "true"
provisioner: rancher.io/local-path
reclaimPolicy: Retain
volumeBindingMode: WaitForFirstConsumer
allowVolumeExpansion: true
```

```bash
kubectl get sc                                   # local-path is also (default)
kubectl annotate sc local-path storageclass.kubernetes.io/is-default-class=false --overwrite
kubectl get sc                                   # only fast-retain is (default)
```

## Question 12: Named port and NodePort

```bash
kubectl edit deploy catalog -n catalog
```

```yaml
        ports:
        - name: http
          containerPort: 80
          protocol: TCP
```

```yaml
apiVersion: v1
kind: Service
metadata:
  name: catalog-np
  namespace: catalog
spec:
  type: NodePort
  selector:
    app: catalog
  ports:
  - port: 80
    targetPort: http        # the named container port
    nodePort: 30081
```

## Question 13: TLS 1.3 only

```bash
kubectl edit cm secure-web-conf -n secure-web       # ssl_protocols TLSv1.3;
kubectl rollout restart deploy/secure-web -n secure-web
kubectl exec tls-client -n secure-web -- curl -sk --tls-max 1.2 https://secure-web   # fails
kubectl exec tls-client -n secure-web -- curl -sk --tlsv1.3 https://secure-web       # secure-web ok
```

Updating the ConfigMap changes the mounted file after a short delay, but nginx only reads its configuration at startup, so the Pods must be restarted.

## Question 14: Patch resources instead of recreating

```bash
kubectl describe pod -n reports -l app=report-api    # 0/3 nodes: Insufficient cpu, Insufficient memory
kubectl patch deploy report-api -n reports --type=json -p='[{"op":"replace",
  "path":"/spec/template/spec/containers/0/resources",
  "value":{"requests":{"cpu":"250m","memory":"256Mi"},"limits":{"cpu":"500m","memory":"512Mi"}}}]'
# or:
kubectl set resources deploy report-api -n reports --requests=cpu=250m,memory=256Mi --limits=cpu=500m,memory=512Mi
kubectl rollout history deploy/report-api -n reports
```
