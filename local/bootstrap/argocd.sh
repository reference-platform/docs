#!/usr/bin/env bash
# Installs ArgoCD and the root app.

set -euo pipefail

context=kind-$CLUSTER_NAME
root_app=https://raw.githubusercontent.com/reference-platform/gitops/main/envs/dev/platform/root.yaml

helm upgrade --install argocd argo-cd \
  --repo https://argoproj.github.io/argo-helm \
  --version "$ARGOCD_CHART_VERSION" \
  --kube-context "$context" \
  --namespace argocd --create-namespace \
  --values bootstrap/argocd-values.yaml \
  --wait --timeout 5m

kubectl --context "$context" apply -f "$root_app"
