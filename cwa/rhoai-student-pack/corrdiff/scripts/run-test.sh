#!/usr/bin/env bash
# 執行本包內的 smoke／inference Job（需已 seed）。
# 發放僅含本包 + corrdiff_for_ocp；不含 GRIB preprocess。
set -euo pipefail

NAMESPACE="${NAMESPACE:-corrdiff-poc}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"
PHASE="${1:-smoke}"

run_job() {
  local job="$1"
  local manifest="$2"
  if [[ ! -f "$manifest" ]]; then
    echo "ERROR: missing manifest: $manifest" >&2
    exit 1
  fi
  oc delete job "$job" -n "$NAMESPACE" --ignore-not-found
  oc apply -f "$manifest"
  echo "Waiting for job/$job ..."
  if oc wait --for=condition=complete "job/$job" -n "$NAMESPACE" --timeout=600s; then
    echo "=== $job: SUCCESS ==="
    oc logs "job/$job" -n "$NAMESPACE" | tail -40
    return 0
  else
    echo "=== $job: FAILED ==="
    oc logs "job/$job" -n "$NAMESPACE" | tail -60 || true
    return 1
  fi
}

case "$PHASE" in
  smoke)
    run_job corrdiff-smoke-test "$ROOT_DIR/k8s/smoke-test-job.yaml"
    ;;
  inference)
    run_job corrdiff-inference "$ROOT_DIR/k8s/inference-job.yaml"
    ;;
  preprocess)
    cat >&2 <<EOF
ERROR: 本發放不含 GRIB preprocess Job。

請用 seed-data.sh 上傳的 CorrdiffInput NC + Workbench notebook（學員主線）。
EOF
    exit 1
    ;;
  all)
    run_job corrdiff-smoke-test "$ROOT_DIR/k8s/smoke-test-job.yaml"
    run_job corrdiff-inference "$ROOT_DIR/k8s/inference-job.yaml"
    ;;
  *)
    echo "Usage: $0 [smoke|inference|all]"
    echo "  （不含 preprocess；請用已 seed 的 NC）"
    exit 1
    ;;
esac
