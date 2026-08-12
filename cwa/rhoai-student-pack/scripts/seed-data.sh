#!/usr/bin/env bash
# Convenience wrapper: forward to corrdiff/scripts/seed-data.sh
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
exec "$ROOT/corrdiff/scripts/seed-data.sh" "$@"
