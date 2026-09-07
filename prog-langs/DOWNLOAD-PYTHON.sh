#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
# shellcheck source=_common.bash
source "$SCRIPT_DIR/_common.bash"

archive_name=$(python_archive_name)
archive="$GLNER_DOWNLOAD_DIR/$archive_name"
url="https://github.com/astral-sh/python-build-standalone/releases/download/${GLNER_PYTHON_BUILD_RELEASE}/${archive_name}"

if [ "${1:-}" = "--dry-run" ]; then
    echo "Python $GLNER_PYTHON_VERSION"
    echo "URL:   $url"
    echo "Cache: $archive"
    exit 0
fi

if [ -s "$archive" ] && tar -tzf "$archive" >/dev/null 2>&1; then
    echo "Already downloaded:"
    echo "  $archive"
    exit 0
fi

rm -f "$archive"
download_file "$url" "$archive"
if ! tar -tzf "$archive" >/dev/null 2>&1; then
    rm -f "$archive"
    fail "Downloaded Python archive is not a valid gzip tar archive"
fi

echo "Downloaded Python archive:"
echo "  $archive"
