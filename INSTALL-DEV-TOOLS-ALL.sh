#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
"$SCRIPT_DIR/prog-langs/INSTALL-PYTHON.sh"
"$SCRIPT_DIR/prog-langs/INSTALL-NODEJS.sh"

echo ""
echo "Development languages are ready."
echo "Activate them in the current shell with:"
echo "  source ./dev/SETUP.bash"
