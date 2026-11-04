#!/usr/bin/env bash
# Waits until every ArgoCD application is Synced and Healthy.

set -euo pipefail

context=kind-$CLUSTER_NAME
deadline=$((SECONDS + ${WAIT_TIMEOUT:-900}))

pending() {
  kubectl --context "$context" -n argocd get applicationsets,applications -o json | jq '
    [.items[]
      | select(
          if .kind == "ApplicationSet"
          then (any(.status.conditions[]?; .type == "ResourcesUpToDate" and .status == "True") | not)
          else (.status.sync.status != "Synced" or .status.health.status != "Healthy")
          end)
    ] as $notready
    | ($notready | length) + (if any(.items[]; .kind == "ApplicationSet") then 0 else 1 end)'
}

until [ "$(pending)" = 0 ]; do
  if [ "$SECONDS" -ge "$deadline" ]; then
    echo "timeout: applications are not ready. Run 'make status'." >&2
    exit 1
  fi
  sleep 5
done

echo "all applications are Synced and Healthy"
