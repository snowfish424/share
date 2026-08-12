#!/usr/bin/env bash
# 部署 CorrDiff 基礎資源（PVC + runner SA；可選 LocalQueue）
# 建議先在 Dashboard 建立專案 corrdiff-poc，再執行本腳本。
set -euo pipefail

NAMESPACE="${NAMESPACE:-corrdiff-poc}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"

echo "=== Deploy CorrDiff to namespace: $NAMESPACE ==="

oc whoami >/dev/null || { echo "ERROR: oc login required"; exit 1; }

if ! oc get namespace "$NAMESPACE" >/dev/null 2>&1; then
  echo "[1/3] Namespace missing — applying k8s/namespace.yaml (NS + LocalQueue + SA)"
  oc apply -f "$ROOT_DIR/k8s/namespace.yaml"
else
  echo "[1/3] Namespace $NAMESPACE exists — ensure LocalQueue + SA"
  # Idempotent: re-apply same manifest (NS labels / LocalQueue / SA)
  oc apply -f "$ROOT_DIR/k8s/namespace.yaml" || true
  if ! oc get sa corrdiff-runner -n "$NAMESPACE" >/dev/null 2>&1; then
    echo "ERROR: serviceaccount/corrdiff-runner missing; check k8s/namespace.yaml" >&2
    exit 1
  fi
fi

echo "[2/3] Apply PVC (cephfs RWX 100Gi)"
oc apply -f "$ROOT_DIR/k8s/pvc.yaml"

echo "[3/3] Wait for PVC bound"
oc wait --for=jsonpath='{.status.phase}'=Bound pvc/corrdiff-workspace -n "$NAMESPACE" --timeout=120s

oc project "$NAMESPACE" >/dev/null
echo ""
echo "=== Deploy complete ==="
oc get ns "$NAMESPACE" --show-labels | head -1
oc get pvc,sa -n "$NAMESPACE"
echo ""
echo "Next: ./scripts/seed-data.sh"
