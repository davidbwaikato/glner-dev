#!/usr/bin/env bash
# Source this file from the glner-workbench root:
#   source ./dev/SETUP.bash

if [ "${BASH_SOURCE[0]}" = "$0" ]; then
    echo "SETUP.bash must be sourced, not executed." >&2
    echo "Use: source ./dev/SETUP.bash" >&2
    exit 2
fi

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
# shellcheck source=prog-langs/ACTIVATE-PYTHON.bash
source "$SCRIPT_DIR/prog-langs/ACTIVATE-PYTHON.bash" || return 1
# shellcheck source=prog-langs/ACTIVATE-NODEJS.bash
source "$SCRIPT_DIR/prog-langs/ACTIVATE-NODEJS.bash" || return 1

export GLNER_DEV_ROOT="$SCRIPT_DIR"
echo "GLNER development environment activated."
