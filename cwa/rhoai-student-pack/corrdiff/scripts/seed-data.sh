#!/usr/bin/env bash
# 將本地程式碼與測試資料上傳到 PVC
# 學員說明（oc 白話）：docs/instructor/05-seed-scripts.md
#
# 用法（在 corrdiff/ 下）：
#   ./scripts/seed-data.sh
# 或指定來源：
#   CORRDIFF_SRC=/path/to/corrdiff_for_ocp ./scripts/seed-data.sh
set -euo pipefail

NAMESPACE="${NAMESPACE:-corrdiff-poc}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"          # .../rhoai-student-pack/corrdiff
PACK_DIR="$(dirname "$ROOT_DIR")"            # .../rhoai-student-pack
WORKSPACES_DIR="$(dirname "$PACK_DIR")"      # .../workspaces（與 corrdiff_for_ocp 同層）
DATE="${CORRDIFF_DATE:-20260707}"

# --- 解析 CORRDIFF_SRC（含 bin／etc／workdir／config）---
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
    if [[ -d "$c/bin" && -d "$c/etc" ]]; then
      echo "$c"
      return 0
    fi
  done
  return 1
}

if ! SRC_APP="$(resolve_src)"; then
  cat >&2 <<EOF
ERROR: 找不到 CorrDiff 本機資料目錄（需含 bin/ 與 etc/）。

預設會找與學員包同層的：
  ${WORKSPACES_DIR}/corrdiff_for_ocp

請擇一：
  1) 把完整資料放在上述路徑
  2) 執行時指定：
       CORRDIFF_SRC=/path/to/corrdiff_for_ocp ./scripts/seed-data.sh
EOF
  exit 1
fi

BIN_SRC="${CORRDIFF_BIN:-$SRC_APP/bin}"
if [[ ! -d "$BIN_SRC" ]]; then
  echo "ERROR: bin/ not found at $BIN_SRC" >&2
  exit 1
fi

GEN_CONFIG="${CORRDIFF_GEN_CONFIG:-}"
if [[ -z "$GEN_CONFIG" ]]; then
  # 發放只有本包 + 同層 corrdiff_for_ocp
  for c in \
    "$ROOT_DIR/config/gen_config.yaml" \
    "$SRC_APP/config/gen_config.yaml"
  do
    if [[ -f "$c" ]]; then
      GEN_CONFIG="$c"
      break
    fi
  done
fi
if [[ -z "${GEN_CONFIG:-}" || ! -f "$GEN_CONFIG" ]]; then
  echo "ERROR: gen_config.yaml not found (set CORRDIFF_GEN_CONFIG=...)" >&2
  exit 1
fi

echo "=== Seed data to PVC ==="
echo "Source app:  $SRC_APP"
echo "bin/:        $BIN_SRC"
echo "gen_config:  $GEN_CONFIG"
echo "Date:        $DATE"
echo "Namespace:   $NAMESPACE"

oc whoami >/dev/null || { echo "ERROR: oc login required"; exit 1; }

# 啟動 seed job（使用 Job 以相容 Kueue 排程）
oc delete job corrdiff-seed -n "$NAMESPACE" --ignore-not-found
oc apply -f "$ROOT_DIR/k8s/seed-pod.yaml"

echo "Waiting for seed job pod..."
sleep 8
POD=$(oc get pods -n "$NAMESPACE" -l job-name=corrdiff-seed -o jsonpath='{.items[0].metadata.name}')
if [[ -z "${POD:-}" ]]; then
  echo "ERROR: seed pod not found" >&2
  exit 1
fi
echo "Seed pod: $POD"
oc wait --for=condition=Ready "pod/$POD" -n "$NAMESPACE" --timeout=300s
DEST="/mnt/corrdiff"

echo "[1/5] Upload bin/ (+ lib/ — bin/lib 常為指向 ../lib 的 symlink)"
oc exec -n "$NAMESPACE" "$POD" -- mkdir -p "$DEST/bin" "$DEST/lib" "$DEST/config" "$DEST/etc" \
  "$DEST/workdir/$DATE" "$DEST/dtg/EC_S2S_AIPP/$DATE" "$DEST/dtg/EC_S2S_PP/$DATE"
oc cp "$BIN_SRC/." "$NAMESPACE/$POD:$DEST/bin/"
# corrdiff_for_ocp/bin/lib -> ../lib；oc cp 只會留下壞掉的 symlink，需另傳真實 lib/
LIB_SRC="${CORRDIFF_LIB:-$SRC_APP/lib}"
if [[ -d "$LIB_SRC" ]]; then
  oc cp "$LIB_SRC/." "$NAMESPACE/$POD:$DEST/lib/"
else
  echo "ERROR: lib/ not found at $LIB_SRC (needed for inference_v1.py imports)" >&2
  exit 1
fi
# 確認 symlink 可解析（否則把實體檔放進 bin/lib）
if ! oc exec -n "$NAMESPACE" "$POD" -- test -f "$DEST/bin/lib/corrdiff_inference.py"; then
  echo "[WARN] bin/lib symlink broken; copying lib files into bin/lib/"
  oc exec -n "$NAMESPACE" "$POD" -- rm -f "$DEST/bin/lib"
  oc exec -n "$NAMESPACE" "$POD" -- mkdir -p "$DEST/bin/lib"
  oc cp "$LIB_SRC/." "$NAMESPACE/$POD:$DEST/bin/lib/"
fi

echo "[2/5] Upload config/"
oc cp "$GEN_CONFIG" "$NAMESPACE/$POD:$DEST/config/gen_config.yaml"

echo "[3/5] Upload etc/ (models ~600MB, may take a few minutes)"
oc cp "$SRC_APP/etc/." "$NAMESPACE/$POD:$DEST/etc/"

echo "[4/5] Upload test input NC (do NOT copy HPC config.yaml — regenerate with SHOME)"
if [ -f "$SRC_APP/workdir/$DATE/CorrdiffInput_EC_RAW_${DATE}.nc" ]; then
  oc cp "$SRC_APP/workdir/$DATE/CorrdiffInput_EC_RAW_${DATE}.nc" \
    "$NAMESPACE/$POD:$DEST/workdir/$DATE/CorrdiffInput_EC_RAW_${DATE}.nc"
else
  echo "[WARN] No CorrdiffInput at $SRC_APP/workdir/$DATE/ — preprocess or place file manually"
fi

echo "[4b/5] Generate config.yaml with SHOME=$DEST (never use HPC /nwpr paths)"
oc exec -n "$NAMESPACE" "$POD" -- python3 "$DEST/bin/config_gen.py" \
  -i "$DEST/config/gen_config.yaml" \
  -o "$DEST/workdir/$DATE/config.yaml" \
  -v "dtg=${DATE}" -v "SHOME=${DEST}"
oc exec -n "$NAMESPACE" "$POD" -- grep -n etc_dir "$DEST/workdir/$DATE/config.yaml"

echo "[5/5] Verify upload"
oc exec -n "$NAMESPACE" "$POD" -- bash -c "
  echo '--- tree ---'
  find $DEST -maxdepth 3 -type f | head -30
  echo '--- sizes ---'
  du -sh $DEST/etc $DEST/bin $DEST/workdir/$DATE 2>/dev/null || true
"

echo ""
echo "=== Seed complete ==="
echo "Next: Workbench 掛 /mnt/corrdiff 後跑 notebooks/01-test-corrdiff-inference.ipynb"
echo "      （可選）./scripts/run-test.sh smoke"
