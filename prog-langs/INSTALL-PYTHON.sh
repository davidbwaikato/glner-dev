#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
# shellcheck source=_common.bash
source "$SCRIPT_DIR/_common.bash"

"$SCRIPT_DIR/DOWNLOAD-PYTHON.sh"
archive="$GLNER_DOWNLOAD_DIR/$(python_archive_name)"
install=$(python_install_path)
python_exe=$(python_base_executable)

python_matches() {
    [ -x "$python_exe" ] || return 1
    version=$($python_exe -c 'import sys; print(".".join(map(str, sys.version_info[:3])))' 2>/dev/null || true)
    [ "$version" = "$GLNER_PYTHON_VERSION" ]
}

if python_matches; then
    echo "Portable Python already installed:"
    echo "  $install"
else
    echo "Installing portable Python $GLNER_PYTHON_VERSION"
    tmp="$GLNER_PROG_LANGS_DIR/.tmp-python-$$"
    rm -rf "$tmp"
    mkdir -p "$tmp"
    trap 'rm -rf "$tmp"' EXIT
    tar -xzf "$archive" -C "$tmp"
    [ -d "$tmp/python" ] || fail "Python archive did not contain the expected python/ directory"
    rm -rf "$install"
    mv "$tmp/python" "$install"
    rm -rf "$tmp"
    trap - EXIT
    python_exe=$(python_base_executable)
    python_matches || fail "Installed Python does not report version $GLNER_PYTHON_VERSION"
    echo "Installed portable Python:"
    echo "  $install"
fi

venv_python=$(python_venv_executable)
venv_ok=0
if [ -x "$venv_python" ]; then
    venv_version=$($venv_python -c 'import sys; print(".".join(map(str, sys.version_info[:3])))' 2>/dev/null || true)
    if [ "$venv_version" = "$GLNER_PYTHON_VERSION" ]; then
        venv_ok=1
    fi
fi

if [ "$venv_ok" -eq 0 ]; then
    echo "Creating virtual environment:"
    echo "  $GLNER_PYTHON_VENV_DIR"
    rm -rf "$GLNER_PYTHON_VENV_DIR"
    "$python_exe" -m venv "$GLNER_PYTHON_VENV_DIR"
else
    echo "Virtual environment already present:"
    echo "  $GLNER_PYTHON_VENV_DIR"
fi

venv_python=$(python_venv_executable)
if [ "${GLNER_DEV_SKIP_PIP_UPGRADE:-0}" != "1" ]; then
    echo "Updating pip/setuptools/wheel in $GLNER_PYTHON_VENV_NAME"
    "$venv_python" -m pip install --upgrade pip setuptools wheel
fi

echo "Python environment ready. Activate with:"
echo "  source ./dev/prog-langs/ACTIVATE-PYTHON.bash"
