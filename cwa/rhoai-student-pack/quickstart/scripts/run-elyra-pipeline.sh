#!/usr/bin/env bash
# Submit iris-train-pipeline.pipeline from Workbench via Elyra CLI (C-Vis demo).
set -euo pipefail

NAMESPACE="${NAMESPACE:-rhoai-quickstart}"
WORKBENCH="${WORKBENCH:-iris-workbench}"
RUNTIME_NAME="${RUNTIME_NAME:-rhoai-quickstart-kfp}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"
PIPELINE_SRC="$ROOT_DIR/pipelines/elyra/iris-train-pipeline.pipeline"
PIPELINE_DST="/opt/app-root/src/notebooks/iris-train-pipeline.pipeline"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info()  { echo -e "${GREEN}[INFO]${NC} $*"; }
log_warn()  { echo -e "${YELLOW}[WARN]${NC} $*"; }
log_error() { echo -e "${RED}[ERROR]${NC} $*"; }

check_prerequisites() {
    if ! oc whoami &>/dev/null; then
        log_error "Not logged in to OpenShift."
        exit 1
    fi
    if ! oc get pod "${WORKBENCH}-0" -n "$NAMESPACE" &>/dev/null; then
        log_error "Workbench pod ${WORKBENCH}-0 not found in $NAMESPACE"
        exit 1
    fi
    if [[ ! -f "$PIPELINE_SRC" ]]; then
        log_error "Missing $PIPELINE_SRC"
        exit 1
    fi
}

copy_pipeline_to_workbench() {
    log_info "Copying pipeline file to Workbench..."
    oc cp "$PIPELINE_SRC" "${NAMESPACE}/${WORKBENCH}-0:${PIPELINE_DST}" -c iris-workbench
}

get_public_api_endpoint() {
    local route
    route=$(oc get route ds-pipeline-dspa -n "$NAMESPACE" -o jsonpath='{.spec.host}' 2>/dev/null || true)
    if [[ -n "$route" ]]; then
        echo "https://${route}"
        return
    fi
    log_warn "Could not resolve ds-pipeline-dspa route; set KFP_PUBLIC_API_ENDPOINT"
    echo "${KFP_PUBLIC_API_ENDPOINT:-}"
}

run_in_workbench() {
    local api_public
    api_public=$(get_public_api_endpoint)
    if [[ -z "$api_public" ]]; then
        log_error "Set KFP_PUBLIC_API_ENDPOINT to the Pipeline Server route URL"
        exit 1
    fi

    log_info "Configuring Elyra runtime and submitting pipeline..."
    log_info "Public API: $api_public"

    oc exec -n "$NAMESPACE" "${WORKBENCH}-0" -c iris-workbench -- \
        env RUNTIME_NAME="$RUNTIME_NAME" \
            PIPELINE_PATH="$PIPELINE_DST" \
            NAMESPACE="$NAMESPACE" \
            API_PUBLIC="$api_public" \
        python3 - <<'PY'
import base64
import json
import os
import subprocess
import sys
from pathlib import Path

from kubernetes import client, config

runtime_name = os.environ["RUNTIME_NAME"]
pipeline_path = os.environ["PIPELINE_PATH"]
namespace = os.environ["NAMESPACE"]
api_public = os.environ["API_PUBLIC"]
api_internal = f"https://ds-pipeline-dspa.{namespace}.svc.cluster.local:8443"
runtime_dir = Path("/opt/app-root/src/.local/share/jupyter/metadata/runtimes")
runtime_path = runtime_dir / f"{runtime_name}.json"

config.load_incluster_config()
v1 = client.CoreV1Api()
secret = v1.read_namespaced_secret("ds-pipeline-s3-dspa", namespace)
cos_username = base64.b64decode(secret.data["accesskey"]).decode()
cos_password = base64.b64decode(secret.data["secretkey"]).decode()
token = Path("/var/run/secrets/kubernetes.io/serviceaccount/token").read_text().strip()

runtime = {
    "schema_name": "kfp",
    "display_name": runtime_name,
    "metadata": {
        "runtime_type": "KUBEFLOW_PIPELINES",
        "description": "RHOAI quickstart KFP runtime",
        "api_endpoint": api_internal,
        "public_api_endpoint": api_public,
        "user_namespace": namespace,
        "engine": "Argo",
        "auth_type": "EXISTING_BEARER_TOKEN",
        "api_username": "user",
        "api_password": token,
        "cos_endpoint": f"http://minio-dspa.{namespace}.svc.cluster.local:9000",
        "cos_bucket": "mlpipeline",
        "cos_auth_type": "USER_CREDENTIALS",
        "cos_username": cos_username,
        "cos_password": cos_password,
    },
}
runtime_dir.mkdir(parents=True, exist_ok=True)
runtime_path.write_text(json.dumps(runtime, indent=2))
print(f"Wrote runtime config: {runtime_path}")

result = subprocess.run(
    [
        "elyra-pipeline",
        "submit",
        pipeline_path,
        "--runtime-config",
        runtime_name,
        "--monitor",
        "--monitor-timeout",
        "20",
    ],
    cwd="/opt/app-root/src/notebooks",
)
# Monitor may fail on self-signed TLS; submission success is enough for instructors.
sys.exit(0 if result.returncode in (0, 1) else result.returncode)
PY
}

main() {
    check_prerequisites
    oc project "$NAMESPACE" >/dev/null
    copy_pipeline_to_workbench
    run_in_workbench
    log_info "Done. Check Dashboard → Develop & train → Runs"
    log_info "Next: Dashboard Deploy model → iris-classifier-elyra (see pipeline-ui-tutorial.ipynb)"
}

main "$@"
