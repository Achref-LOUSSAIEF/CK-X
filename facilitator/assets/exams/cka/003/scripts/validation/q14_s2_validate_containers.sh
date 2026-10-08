#!/bin/bash
pass() { echo "✅ $1"; exit 0; }
fail() { echo "❌ $1"; exit 1; }
P=$(kubectl get pod web-logger -n sidecar-lab -o json 2>/dev/null) || fail "Pod web-logger not found"
echo "$P" | jq -e '.spec.initContainers[0].name=="setup" and (.spec.initContainers[0].restartPolicy // "") != "Always"' >/dev/null || fail "First init container must be 'setup' (regular init container)"
echo "$P" | jq -e '.spec.initContainers[] | select(.name=="log-tailer") | .restartPolicy=="Always"' >/dev/null || fail "log-tailer must be an init container with restartPolicy: Always"
echo "$P" | jq -e '[.spec.volumes[] | select(.emptyDir != null) | .name] | (index("html") != null and index("logs") != null)' >/dev/null || fail "emptyDir volumes html and logs required"
echo "$P" | jq -e '.spec.containers[] | select(.name=="nginx") | ([.volumeMounts[] | "\(.name):\(.mountPath)"] | (index("html:/usr/share/nginx/html") != null and index("logs:/var/log/nginx") != null))' >/dev/null || fail "nginx volume mounts incorrect"
pass "Containers configured correctly"
