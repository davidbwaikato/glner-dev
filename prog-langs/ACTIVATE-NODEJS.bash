#!/usr/bin/env bash
# Source this file; do not execute it.

# Keep this locator private to this sourced script so that it cannot overwrite
# dev/SETUP.bash's own directory variable.
_GLNER_NODE_ACTIVATE_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
# shellcheck source=_common.bash
source "$_GLNER_NODE_ACTIVATE_DIR/_common.bash"

install=$(node_install_path) || {
    unset _GLNER_NODE_ACTIVATE_DIR
    return 1
}
node_exe=$(node_executable) || {
    unset _GLNER_NODE_ACTIVATE_DIR
    return 1
}
if [ ! -x "$node_exe" ]; then
    echo "Node.js is not installed." >&2
    echo "Run: ./dev/prog-langs/INSTALL-NODEJS.sh" >&2
    unset _GLNER_NODE_ACTIVATE_DIR
    return 1
fi

os=$(detect_os) || {
    unset _GLNER_NODE_ACTIVATE_DIR
    return 1
}
if [ "$os" = windows ]; then
    node_bin="$install"
else
    node_bin="$install/bin"
fi

# Avoid growing PATH with another identical entry every time SETUP.bash is
# sourced in the same shell.
case ":$PATH:" in
    *":$node_bin:"*) ;;
    *) export PATH="$node_bin:$PATH" ;;
esac

export GLNER_NODE_ROOT="$install"
echo "Activated Node.js: $(node --version)"
echo "npm: $(npm --version)"

unset install
unset node_exe
unset os
unset node_bin
unset _GLNER_NODE_ACTIVATE_DIR
