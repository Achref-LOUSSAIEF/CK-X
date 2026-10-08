#!/bin/bash
# Setup for Question 12
kubectl create namespace crd-db --dry-run=client -o yaml | kubectl apply -f -

kubectl apply -f - <<'EOF'
apiVersion: apiextensions.k8s.io/v1
kind: CustomResourceDefinition
metadata:
  name: databases.stable.example.com
spec:
  group: stable.example.com
  scope: Namespaced
  names:
    kind: Database
    plural: databases
    singular: database
    shortNames: ["db"]
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
            required: ["engine"]
            properties:
              engine:
                type: string
                enum: ["postgres", "mysql"]
              version:
                type: string
              storageGB:
                type: integer
EOF
kubectl wait --for=condition=Established crd/databases.stable.example.com --timeout=60s
kubectl apply -f - <<'EOF'
apiVersion: stable.example.com/v1
kind: Database
metadata:
  name: legacy-db
  namespace: crd-db
spec:
  engine: mysql
  version: "5.7"
  storageGB: 5
EOF

echo "Setup completed for Question 12"
exit 0
