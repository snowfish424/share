#!/usr/bin/env bash
# Local podman validation WITHOUT OpenShift.
# On Apple Silicon, amd64 images often crash under qemu — still verify inspect/save/load.
set -euo pipefail

IMAGE="${IMAGE:-localhost/corrdiff-workbench:latest}"
ENGINE="${CONTAINER_ENGINE:-podman}"

echo "==> Inspect image: $IMAGE"
$ENGINE image inspect "$IMAGE" --format 'Id={{.Id}} Size={{.Size}} Arch={{.Architecture}} Os={{.Os}}'

HOST_ARCH="$(uname -m)"
IMG_ARCH="$($ENGINE image inspect "$IMAGE" --format '{{.Architecture}}')"
echo "Host arch: $HOST_ARCH | Image arch: $IMG_ARCH"

echo "==> Round-trip save/load smoke (tmp tar)..."
TMP_TAR="$(mktemp -t corrdiff-wb-XXXXXX).tar"
trap 'rm -f "$TMP_TAR"' EXIT
$ENGINE save -o "$TMP_TAR" "$IMAGE"
echo "  saved $(du -h "$TMP_TAR" | awk '{print $1}')"
$ENGINE tag "$IMAGE" localhost/corrdiff-workbench:loadtest
$ENGINE rmi localhost/corrdiff-workbench:loadtest >/dev/null
$ENGINE load -i "$TMP_TAR" >/dev/null
echo "  load OK"

if [[ "$HOST_ARCH" == "arm64" || "$HOST_ARCH" == "aarch64" ]] && [[ "$IMG_ARCH" == "amd64" ]]; then
  echo ""
  echo "NOTE: Apple Silicon + amd64 image — skipping 'podman run' python test"
  echo "      (qemu often segfaults). Packages were verified at build time."
  echo "      Full runtime: Linux amd64 host, or OpenShift Workbench after Import."
  exit 0
fi

echo "==> Runtime import check..."
$ENGINE run --rm --entrypoint python "$IMAGE" -c \
  "import torch, modulus, jupyterlab, netCDF4; print('ok', torch.__version__, torch.version.cuda)"
echo "PASS"
