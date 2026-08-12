#!/usr/bin/env bash
# Prepare namespace resources for Iris Pipeline Editor (RBAC, DSPA).
set -euo pipefail

NAMESPACE="${NAMESPACE:-rhoai-quickstart}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info()  { echo -e "${GREEN}[INFO]${NC} $*"; }
log_warn()  { echo -e "${YELLOW}[WARN]${NC} $*"; }
log_error() { echo -e "${RED}[ERROR]${NC} $*"; }

check_prerequisites() {
    if ! oc whoami &>/dev/null; then
        log_error "Not logged in to OpenShift. Run: oc login <API_URL>"
        exit 1
    fi
}

ensure_namespace() {
    if ! oc get namespace "$NAMESPACE" &>/dev/null; then
        log_error "Namespace $NAMESPACE not found. Create the project in Dashboard first."
        exit 1
    fi
    oc project "$NAMESPACE" >/dev/null
    log_info "Using namespace: $NAMESPACE"
}

apply_pipeline_prereqs() {
    log_info "Applying pipeline RBAC for service account 'pipeline'..."
    sed "s/namespace: rhoai-quickstart/namespace: $NAMESPACE/" \
        "$ROOT_DIR/k8s/rbac.yaml" | oc apply -f -

    if ! oc get dspa dspa -n "$NAMESPACE" &>/dev/null; then
        log_info "Deploying pipeline server (DSPA)..."
        oc apply -n "$NAMESPACE" -f "$ROOT_DIR/k8s/dspa.yaml"
        log_warn "DSPA provisioning may take several minutes. Monitor: oc get dspa dspa -n $NAMESPACE -w"
    else
        log_info "DSPA already exists in $NAMESPACE"
    fi
}

check_pipeline_server() {
    if oc get deployment -l app=ml-pipeline-ui -n "$NAMESPACE" &>/dev/null 2>&1; then
        return 0
    fi
    if oc get deployment -n "$NAMESPACE" 2>/dev/null | grep -qi pipeline; then
        return 0
    fi
    log_warn "No pipeline server deployment found in $NAMESPACE."
    log_warn "Configure one in Dashboard: Project → Configure pipeline server"
}

print_next_steps() {
    echo ""
    log_info "Prerequisites applied. Next steps (Dashboard / JupyterLab):"
    echo ""
    echo "  1. Configure pipeline server (if not done):"
    echo "     Dashboard → Projects → $NAMESPACE → Configure pipeline server"
    echo ""
    echo "  2. Create Workbench (Data Science CPU 3.4) AFTER pipeline server is ready"
    echo ""
    echo "  3. Iris Pipeline Editor:"
    echo "     Upload pipelines/elyra/iris-train-pipeline.pipeline → Run → Deploy"
    echo "     Guide: docs/pipeline-ui-tutorial.md / docs/00-hands-on-onepage.md"
    echo ""
}

main() {
    check_prerequisites
    ensure_namespace
    apply_pipeline_prereqs
    check_pipeline_server
    print_next_steps
}

main "$@"
