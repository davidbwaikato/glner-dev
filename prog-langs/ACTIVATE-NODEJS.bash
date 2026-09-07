#!/usr/bin/env bash
# Source this file; do not execute it.
SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
# shellcheck source=_common.bash
source "$SCRIPT_DIR/_common.bash"

install=$(node_install_path) || return 1
node_exe=$(node_executable) || return 1
if [ ! -x "$node_exe" ]; then
    echo "Node.js is not installed." >&2
    echo "Run: ./dev/prog-langs/INSTALL-NODEJS.sh" >&2
    return 1
fi

os=$(detect_os) || return 1
if [ "$os" = windows ]; then
    node_bin="$install"
else
    node_bin="$install/bin"
fi
export PATH="$node_bin:$PATH"
export GLNER_NODE_ROOT="$install"
echo "Activated Node.js: $(node --version)"
echo "npm: $(npm --version)"
