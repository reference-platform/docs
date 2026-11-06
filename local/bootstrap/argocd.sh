#!/usr/bin/env bash
# Installs ArgoCD and the root app. The chart version and the values files come
# from the ArgoCD Application in the gitops repo, so ArgoCD can update itself
# from the same files.

set -euo pipefail

context=kind-$CLUSTER_NAME
gitops=https://raw.githubusercontent.com/reference-platform/gitops/main

app=$(curl -fsSL "$gitops/platform/argocd/$GITOPS_CLUSTER/application.yaml")

values=()
for file in $(yq '.spec.sources[0].helm.valueFiles[]' <<<"$app"); do
  url=$gitops/${file#'$values/'}
  if curl -fsI "$url" >/dev/null; then values+=(--values "$url"); fi
done

helm upgrade --install argocd "$(yq '.spec.sources[0].chart' <<<"$app")" \
  --repo "$(yq '.spec.sources[0].repoURL' <<<"$app")" \
  --version "$(yq '.spec.sources[0].targetRevision' <<<"$app")" \
  --kube-context "$context" \
  --namespace "$(yq '.spec.destination.namespace' <<<"$app")" --create-namespace \
  "${values[@]}" \
  --wait --timeout 5m

kubectl --context "$context" apply -f "$gitops/clusters/$GITOPS_CLUSTER/root.yaml"
