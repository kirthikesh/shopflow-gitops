#!/usr/bin/env bash
# Installs (or upgrades) Argo CD and registers the ShopFlow environments.
# This is the only thing ever pushed to the cluster; after it, Argo CD pulls
# everything from this repository.
#
# Idempotent: safe to run on every pipeline run and after recreating the cluster.
# Needs kubectl pointed at the cluster, and helm.
set -euo pipefail
cd "$(dirname "$0")/.."

ARGOCD_CHART_VERSION=10.11.6   # Argo CD v3.5.6

if helm status argocd -n argocd >/dev/null 2>&1 &&
   [ "$(helm list -n argocd -f '^argocd$' -o json | jq -r '.[0].chart')" = "argo-cd-$ARGOCD_CHART_VERSION" ]; then
  echo "Argo CD $ARGOCD_CHART_VERSION already installed."
else
  helm repo add argo https://argoproj.github.io/argo-helm --force-update >/dev/null
  helm upgrade --install argocd argo/argo-cd \
    --version "$ARGOCD_CHART_VERSION" \
    --namespace argocd --create-namespace \
    --values bootstrap/argocd-values.yaml \
    --wait --timeout 10m
fi

kubectl apply -f apps/shopflow.yaml
echo "Argo CD is managing: $(kubectl -n argocd get applications -o name 2>/dev/null | tr '\n' ' ')"
