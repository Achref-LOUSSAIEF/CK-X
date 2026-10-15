#!/bin/bash
pass() { echo "✅ $1"; exit 0; }
fail() { echo "❌ $1"; exit 1; }
D=$(kubectl get deploy cms -n blog -o json 2>/dev/null) || fail "Deployment cms not found"
N=$(kubectl get node k3d-cluster-agent-1 -o json) || fail "Node k3d-cluster-agent-1 not found"
echo "$D" | jq -e '.spec.template.spec.nodeSelector["kubernetes.io/hostname"]=="k3d-cluster-agent-1"' >/dev/null || fail "The Pods must still run on k3d-cluster-agent-1"
echo "$D" | jq -e '(.spec.template.spec.initContainers | length)==1 and (.spec.template.spec.containers | length)==1' >/dev/null || fail "The containers of cms must not be added or removed"
# CPU in millicores, memory in bytes
cpu() { awk -v v="$1" 'BEGIN { if (v == "") { print 0; exit } if (v ~ /m$/) { sub(/m$/, "", v); printf "%d", v } else printf "%d", v * 1000 }'; }
mem() { awk -v v="$1" 'BEGIN { n = v + 0; u = v; sub(/^[0-9.]+/, "", u)
  f["Ki"]=1024; f["Mi"]=1048576; f["Gi"]=1073741824; f["Ti"]=1099511627776; f["k"]=1e3; f["M"]=1e6; f["G"]=1e9; f["T"]=1e12; f[""]=1
  printf "%.0f", n * f[u] }'; }
IC=$(echo "$D" | jq -r '.spec.template.spec.initContainers[0].resources.requests.cpu // ""')
IM=$(echo "$D" | jq -r '.spec.template.spec.initContainers[0].resources.requests.memory // ""')
CC=$(echo "$D" | jq -r '.spec.template.spec.containers[0].resources.requests.cpu // ""')
CM=$(echo "$D" | jq -r '.spec.template.spec.containers[0].resources.requests.memory // ""')
[ "$(cpu "$IC")" = "$(cpu "$CC")" ] && [ "$(mem "$IM")" = "$(mem "$CM")" ] || fail "The init container and the cms container must have the same requests (init: $IC/$IM, cms: $CC/$CM)"
AC=$(cpu "$(echo "$N" | jq -r '.status.allocatable.cpu')")
AM=$(mem "$(echo "$N" | jq -r '.status.allocatable.memory')")
C=$(cpu "$CC"); M=$(mem "$CM")
awk -v c="$C" -v a="$AC" 'BEGIN { exit !(c >= a * 0.2 && c <= a * 0.3) }' || fail "The CPU request $CC is not between 20% and 30% of the node's allocatable CPU (${AC}m)"
awk -v m="$M" -v a="$AM" 'BEGIN { exit !(m >= a * 0.2 && m <= a * 0.3) }' || fail "The memory request $CM is not between 20% and 30% of the node's allocatable memory ($AM bytes)"
pass "Requests: $CC CPU and $CM memory per Pod, the same for both containers"
