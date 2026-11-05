#!/usr/bin/env bash
# Installs ArgoCD and the root app. The chart version and the values come from
# the gitops repo, so ArgoCD can update itself from the same files.

set -euo pipefail

context=kind-$CLUSTER_NAME
gitops=https://raw.githubusercontent.com/reference-platform/gitops/main/envs/dev/platform

config=$(curl -fsSL "$gitops/argocd/config.yaml")

helm upgrade --install argocd "$(yq .chart.name <<<"$config")" \
  --repo "$(yq .chart.repo <<<"$config")" \
  --version "$(yq .chart.version <<<"$config")" \
  --kube-context "$context" \
  --namespace "$(yq .namespace <<<"$config")" --create-namespace \
  --values "$gitops/argocd/values.yaml" \
  --wait --timeout 5m

kubectl --context "$context" apply -f "$gitops/root.yaml"
