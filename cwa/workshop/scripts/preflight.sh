#!/usr/bin/env bash
set -euo pipefail
mode="${1:---local}"
case "$mode" in --local|--ocp) ;; *) printf 'Usage: bash scripts/preflight.sh [--local|--ocp]\n'; exit 1;; esac
for tool in podman python3 curl; do
  command -v "$tool" >/dev/null || { printf 'Missing tool: %s\n' "$tool"; exit 1; }
done
podman --version
podman info --format '{{.Host.Arch}}'
if [ "$mode" = --local ]; then
  printf 'Local prerequisites passed. OCP access and a Registry are not required for build/run exercises.\n'
  exit 0
fi
command -v oc >/dev/null || { printf 'Missing tool: oc\n'; exit 1; }
: "${PROJECT:?Run source workshop.env first}"
: "${REGISTRY:?Run source workshop.env first}"
: "${ARCH:?Run source workshop.env first}"
case "$REGISTRY" in *.invalid*) printf 'Replace the example registry first.\n'; exit 1;; esac
oc version --client
oc whoami
oc get project "$PROJECT" -o name
for resource in deployments.apps services configmaps secrets serviceaccounts persistentvolumeclaims routes.route.openshift.io; do
  if [ "$(oc -n "$PROJECT" auth can-i create "$resource")" != yes ]; then
    printf 'Cannot create %s in %s\n' "$resource" "$PROJECT"
    exit 1
  fi
done
printf 'Client-side prerequisites passed. Registry push, node pull and Route access still require a rehearsal.\n'
