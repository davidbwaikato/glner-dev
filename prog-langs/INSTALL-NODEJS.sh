#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
# shellcheck source=_common.bash
source "$SCRIPT_DIR/_common.bash"

"$SCRIPT_DIR/DOWNLOAD-NODEJS.sh"
archive="$GLNER_DOWNLOAD_DIR/$(node_archive_name)"
install=$(node_install_path)
node_exe=$(node_executable)
platform=$(node_platform)
tag=$(printf '%s' "$platform" | cut -d'|' -f2)
ext=$(printf '%s' "$platform" | cut -d'|' -f3)
top="node-v${GLNER_NODE_VERSION}-${tag}"

node_matches() {
    [ -x "$node_exe" ] || return 1
    version=$($node_exe --version 2>/dev/null || true)
    [ "$version" = "v$GLNER_NODE_VERSION" ]
}

if node_matches; then
    echo "Node.js already installed:"
    echo "  $install"
    exit 0
fi

echo "Installing Node.js $GLNER_NODE_VERSION"
tmp="$GLNER_PROG_LANGS_DIR/.tmp-node-$$"
rm -rf "$tmp"
mkdir -p "$tmp"
trap 'rm -rf "$tmp"' EXIT

case "$ext" in
    tar.gz)
        tar -xzf "$archive" -C "$tmp"
        ;;
    zip)
        if have_command unzip; then
            unzip -q "$archive" -d "$tmp"
        elif have_command powershell.exe && have_command cygpath; then
            win_archive=$(cygpath -w "$archive")
            win_tmp=$(cygpath -w "$tmp")
            powershell.exe -NoProfile -Command \
                "Expand-Archive -LiteralPath '$win_archive' -DestinationPath '$win_tmp' -Force"
        else
            fail "Need unzip (or PowerShell under Git Bash) to unpack $archive"
        fi
        ;;
    *) fail "Unsupported Node.js archive extension: $ext" ;;
esac

[ -d "$tmp/$top" ] || fail "Node.js archive did not contain expected directory $top"
rm -rf "$install"
mv "$tmp/$top" "$install"
rm -rf "$tmp"
trap - EXIT

node_exe=$(node_executable)
node_matches || fail "Installed Node.js does not report v$GLNER_NODE_VERSION"

echo "Installed Node.js:"
echo "  $install"
echo "Activate with:"
echo "  source ./dev/prog-langs/ACTIVATE-NODEJS.bash"
