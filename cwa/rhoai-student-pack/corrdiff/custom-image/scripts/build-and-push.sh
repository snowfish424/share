#!/usr/bin/env bash
# Build CorrDiff Workbench image (amd64) and optionally push to Quay.
#
# Usage:
#   ./scripts/build-and-push.sh              # build + local tag only
#   ./scripts/build-and-push.sh --push       # build + push quay.io/cwa/rhoai/...
#   SKIP_BUILD=1 ./scripts/build-and-push.sh --push   # retag existing local image + push
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
IMAGE_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

IMAGE_NAME="${IMAGE_NAME:-corrdiff-workbench}"
IMAGE_TAG="${IMAGE_TAG:-latest}"
LOCAL_REF="localhost/${IMAGE_NAME}:${IMAGE_TAG}"
QUAY_ORG="${QUAY_ORG:-quay.io/cwa/rhoai}"
REMOTE_REF="${QUAY_ORG}/${IMAGE_NAME}:${IMAGE_TAG}"
ENGINE="${CONTAINER_ENGINE:-podman}"
DO_PUSH=0

for arg in "$@"; do
  case "$arg" in
    --push) DO_PUSH=1 ;;
    -h|--help)
      echo "Usage: $0 [--push]"
      exit 0
      ;;
  esac
done

echo "==> Engine: $ENGINE"
echo "==> Local:  $LOCAL_REF"
echo "==> Remote: $REMOTE_REF"

if [[ "${SKIP_BUILD:-0}" != "1" ]]; then
  echo "==> Building (linux/amd64)..."
  $ENGINE build --platform linux/amd64 \
    -f "${IMAGE_DIR}/Containerfile" \
    -t "$LOCAL_REF" \
    "$IMAGE_DIR"
else
  echo "==> SKIP_BUILD=1 — using existing $LOCAL_REF"
  $ENGINE image exists "$LOCAL_REF" || {
    echo "ERROR: $LOCAL_REF not found" >&2
    exit 1
  }
fi

echo "==> Tag for Quay..."
$ENGINE tag "$LOCAL_REF" "$REMOTE_REF"

if [[ "$DO_PUSH" -eq 1 ]]; then
  echo "==> Push $REMOTE_REF"
  $ENGINE push "$REMOTE_REF"
  echo "==> Done. Import in OAI Dashboard:"
  echo "    Image location: $REMOTE_REF"
else
  echo "==> Build OK (not pushed). Next:"
  echo "    ./scripts/podman-local-test.sh"
  echo "    $0 --push"
fi
