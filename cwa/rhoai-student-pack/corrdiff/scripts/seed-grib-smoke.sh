#!/usr/bin/env bash
# Upload a 3-day GRIB smoke set to PVC (init + 2 leads ≈ 1.6Gi).
# Learner-facing explanation: docs/instructor/05-seed-scripts.md
#
# 用法（在 corrdiff/ 下）：
#   ./scripts/seed-grib-smoke.sh
#   CORRDIFF_SRC=/path/to/corrdiff_for_ocp ./scripts/seed-grib-smoke.sh
#
# 注意：發放僅含本包 + corrdiff_for_ocp，不含 preprocess Job。
# 學員主線請用 seed-data.sh 的 CorrdiffInput NC，不要依賴本腳本。
set -euo pipefail

NAMESPACE="${NAMESPACE:-corrdiff-poc}"
DATE="${CORRDIFF_DATE:-20260707}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"
PACK_DIR="$(dirname "$ROOT_DIR")"
WORKSPACES_DIR="$(dirname "$PACK_DIR")"

resolve_src() {
  local c
  for c in \
    "${CORRDIFF_SRC:-}" \
    "${WORKSPACES_DIR}/corrdiff_for_ocp" \
    "${PACK_DIR}/../corrdiff_for_ocp" \
    "${PACK_DIR}/corrdiff_for_ocp"
  do
    [[ -n "$c" ]] || continue
    c="$(cd "$c" 2>/dev/null && pwd)" || continue
    if [[ -d "$c/dat/EC_S2S" || -d "$c/bin" ]]; then
      echo "$c"
      return 0
    fi
  done
  return 1
}

if ! SRC_APP="$(resolve_src)"; then
  cat >&2 <<EOF
ERROR: 找不到 CorrDiff 本機資料目錄（需含 dat/EC_S2S/）。

預設會找：
  ${WORKSPACES_DIR}/corrdiff_for_ocp

請指定：
  CORRDIFF_SRC=/path/to/corrdiff_for_ocp ./scripts/seed-grib-smoke.sh
EOF
  exit 1
fi

RAW_SRC="${SRC_APP}/dat/EC_S2S/${DATE}"
DEST="/mnt/corrdiff/dat/EC_S2S/${DATE}"

# init day + next 2 calendar days
D0="$DATE"
D1=$(date -j -f "%Y%m%d" -v+1d "$DATE" "+%Y%m%d" 2>/dev/null || date -d "${DATE:0:4}-${DATE:4:2}-${DATE:6:2} +1 day" +%Y%m%d)
D2=$(date -j -f "%Y%m%d" -v+2d "$DATE" "+%Y%m%d" 2>/dev/null || date -d "${DATE:0:4}-${DATE:4:2}-${DATE:6:2} +2 day" +%Y%m%d)

FILES=(
  "C2F.${D0}00.${D0}"
  "C2F.${D0}00.${D1}"
  "C2F.${D0}00.${D2}"
)

echo "=== Seed 3-day GRIB smoke ==="
echo "SRC=$RAW_SRC"
echo "DEST=$DEST"
echo "FILES=${FILES[*]}"

oc whoami >/dev/null || { echo "ERROR: oc login required"; exit 1; }

if [[ ! -d "$RAW_SRC" ]]; then
  echo "ERROR: RAW dir not found: $RAW_SRC" >&2
  exit 1
fi

POD=$(oc get pods -n "$NAMESPACE" -l job-name=corrdiff-seed -o jsonpath='{.items[0].metadata.name}' 2>/dev/null || true)
if [ -z "$POD" ] || [ "$(oc get pod "$POD" -n "$NAMESPACE" -o jsonpath='{.status.phase}' 2>/dev/null)" != "Running" ]; then
  echo "Starting seed job..."
  oc delete job corrdiff-seed -n "$NAMESPACE" --ignore-not-found
  oc apply -f "$ROOT_DIR/k8s/seed-pod.yaml"
  sleep 8
  POD=$(oc get pods -n "$NAMESPACE" -l job-name=corrdiff-seed -o jsonpath='{.items[0].metadata.name}')
  oc wait --for=condition=Ready "pod/$POD" -n "$NAMESPACE" --timeout=300s
fi
echo "Seed pod: $POD"

WB="/mnt/corrdiff/workdir/${DATE}/CorrdiffInput_EC_RAW_${DATE}.nc"
if oc exec -n "$NAMESPACE" "$POD" -- test -f "$WB"; then
  echo "Backing up existing CorrdiffInput -> .full-backup.nc"
  oc exec -n "$NAMESPACE" "$POD" -- cp -f "$WB" "${WB}.full-backup.nc" || true
fi

echo "Replacing RAW dir with 3-day set..."
oc exec -n "$NAMESPACE" "$POD" -- rm -rf "$DEST"
oc exec -n "$NAMESPACE" "$POD" -- mkdir -p "$DEST"

for f in "${FILES[@]}"; do
  test -f "${RAW_SRC}/${f}" || { echo "ERROR: missing ${RAW_SRC}/${f}"; exit 1; }
  echo "  upload $f ($(du -h "${RAW_SRC}/${f}" | awk '{print $1}'))"
  oc cp "${RAW_SRC}/${f}" "${NAMESPACE}/${POD}:${DEST}/${f}"
done

oc exec -n "$NAMESPACE" "$POD" -- bash -c "ls -lh $DEST; echo count=\$(ls -1 $DEST | wc -l); du -sh $DEST"
echo "=== Done ==="
echo "本發放不含 preprocess Job。學員主線請用 seed-data.sh 的 CorrdiffInput NC。"
