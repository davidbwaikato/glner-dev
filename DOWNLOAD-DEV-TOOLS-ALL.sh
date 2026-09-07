#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
"$SCRIPT_DIR/prog-langs/DOWNLOAD-PYTHON.sh" "$@"
"$SCRIPT_DIR/prog-langs/DOWNLOAD-NODEJS.sh" "$@"
