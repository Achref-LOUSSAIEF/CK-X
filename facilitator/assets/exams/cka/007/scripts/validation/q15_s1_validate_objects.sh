#!/bin/bash
pass() { echo "✅ $1"; exit 0; }
fail() { echo "❌ $1"; exit 1; }
P=$(kubectl get validatingadmissionpolicy require-two-replicas -o json 2>/dev/null) || fail "ValidatingAdmissionPolicy require-two-replicas not found"
echo "$P" | jq -e '[.spec.matchConstraints.resourceRules[] | select((.resources|index("deployments")) and (.apiGroups|index("apps")) and (.operations|index("CREATE")) and (.operations|index("UPDATE")))] | length > 0' >/dev/null || fail "Policy must match CREATE and UPDATE of apps deployments"
B=$(kubectl get validatingadmissionpolicybinding require-two-replicas-binding -o json 2>/dev/null) || fail "Binding require-two-replicas-binding not found"
echo "$B" | jq -e '.spec.policyName=="require-two-replicas" and (.spec.validationActions|index("Deny")) and .spec.matchResources.namespaceSelector.matchLabels.env=="prod"' >/dev/null \
  && pass "Policy and binding correct" || fail "Binding must reference the policy, use Deny and select namespaces labeled env=prod"
