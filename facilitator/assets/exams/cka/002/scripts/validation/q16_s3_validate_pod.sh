#!/bin/bash
# Validate admin-pod and the effective permissions of the app-admin ServiceAccount.
set -e

NS="cluster-admin"
SA="system:serviceaccount:$NS:app-admin"

kubectl get pod admin-pod -n $NS >/dev/null 2>&1 || {
    echo "Pod admin-pod not found in namespace $NS"
    exit 1
}

POD_SA=$(kubectl get pod admin-pod -n $NS -o jsonpath='{.spec.serviceAccountName}')
if [[ "$POD_SA" != "app-admin" ]]; then
    echo "admin-pod does not use the app-admin ServiceAccount (got '$POD_SA')"
    exit 1
fi

IMAGE=$(kubectl get pod admin-pod -n $NS -o jsonpath='{.spec.containers[0].image}')
if [[ "$IMAGE" != *"bitnami/kubectl"* ]]; then
    echo "admin-pod does not use the bitnami/kubectl image (got '$IMAGE')"
    exit 1
fi

AUTOMOUNT=$(kubectl get pod admin-pod -n $NS -o jsonpath='{.spec.automountServiceAccountToken}')
if [[ "$AUTOMOUNT" == "false" ]]; then
    echo "admin-pod disables ServiceAccount token automounting"
    exit 1
fi

PHASE=$(kubectl get pod admin-pod -n $NS -o jsonpath='{.status.phase}')
if [[ "$PHASE" != "Running" ]]; then
    echo "admin-pod is not Running (phase: $PHASE)"
    exit 1
fi

can() { kubectl auth can-i "$1" "$2" --as="$SA" -n $NS 2>/dev/null; }

for check in "list pods" "get pods" "watch pods" "list deployments.apps" "get deployments.apps" \
             "watch deployments.apps" "update deployments.apps" "create configmaps" "delete configmaps"; do
    set -- $check
    if [[ "$(can "$1" "$2")" != "yes" ]]; then
        echo "app-admin cannot $1 $2"
        exit 1
    fi
done

if [[ "$(can create pods)" != "no" ]]; then
    echo "app-admin can create pods, but it should not"
    exit 1
fi

echo "admin-pod and permissions validation successful"
exit 0
