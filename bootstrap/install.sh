#!/usr/bin/env bash
# Installs (or upgrades) Argo CD and Argo Rollouts, and registers the ShopFlow environments.
# This is the only thing ever pushed to the cluster; after it, Argo CD pulls
# everything from this repository.
#
# Idempotent: safe to run on every pipeline run and after recreating the cluster.
# Needs kubectl pointed at the cluster, and helm.
set -euo pipefail
cd "$(dirname "$0")/.."

# Installs a pinned chart unless that exact version is already there.
#   install_chart <release> <namespace> <chart> <version> <values file>
install_chart() {
  local release=$1 ns=$2 chart=$3 version=$4 values=$5
  if [ "$(helm list -n "$ns" -f "^$release\$" -o json 2>/dev/null | jq -r '.[0].chart // empty')" = "$chart-$version" ]; then
    echo "$chart $version already installed."
    return
  fi
  helm repo add argo https://argoproj.github.io/argo-helm --force-update >/dev/null
  helm upgrade --install "$release" "argo/$chart" \
    --version "$version" \
    --namespace "$ns" --create-namespace \
    --values "$values" \
    --wait --timeout 10m
}

install_chart argocd        argocd        argo-cd       10.11.6 bootstrap/argocd-values.yaml        # Argo CD v3.5.6
install_chart argo-rollouts argo-rollouts argo-rollouts 2.43.8  bootstrap/argo-rollouts-values.yaml # Argo Rollouts v1.10.1

kubectl apply -f apps/shopflow.yaml
echo "Argo CD is managing: $(kubectl -n argocd get applications -o name 2>/dev/null | tr '\n' ' ')"
