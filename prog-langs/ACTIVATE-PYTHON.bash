#!/usr/bin/env bash
# Source this file; do not execute it.
SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
# shellcheck source=_common.bash
source "$SCRIPT_DIR/_common.bash"

activate=$(python_venv_activate) || return 1
if [ ! -f "$activate" ]; then
    echo "Python environment is not installed." >&2
    echo "Run: ./dev/prog-langs/INSTALL-PYTHON.sh" >&2
    return 1
fi
# shellcheck disable=SC1090
source "$activate"
export GLNER_PYTHON_VENV="$GLNER_PYTHON_VENV_DIR"
echo "Activated Python: $(python --version 2>&1)"
echo "Virtual environment: $GLNER_PYTHON_VENV_DIR"
