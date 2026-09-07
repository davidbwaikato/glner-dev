#!/usr/bin/env bash
# Source this file from the glner-workbench root:
#   source ./dev/SETUP.bash

if [ "${BASH_SOURCE[0]}" = "$0" ]; then
    echo "SETUP.bash must be sourced, not executed." >&2
    echo "Use: source ./dev/SETUP.bash" >&2
    exit 2
fi

# Use a setup-specific variable name here.  The scripts sourced below also need
# to locate themselves; using the generic name SCRIPT_DIR in all of them means
# that a child script can overwrite the parent's value because sourced scripts
# run in the same shell.
_GLNER_SETUP_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)

# shellcheck source=prog-langs/ACTIVATE-PYTHON.bash
source "$_GLNER_SETUP_DIR/prog-langs/ACTIVATE-PYTHON.bash" || {
    unset _GLNER_SETUP_DIR
    return 1
}

# shellcheck source=prog-langs/ACTIVATE-NODEJS.bash
source "$_GLNER_SETUP_DIR/prog-langs/ACTIVATE-NODEJS.bash" || {
    unset _GLNER_SETUP_DIR
    return 1
}

export GLNER_DEV_ROOT="$_GLNER_SETUP_DIR"
unset _GLNER_SETUP_DIR

echo "GLNER development environment activated."
