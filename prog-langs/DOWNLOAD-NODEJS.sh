#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
# shellcheck source=_common.bash
source "$SCRIPT_DIR/_common.bash"

archive_name=$(node_archive_name)
archive="$GLNER_DOWNLOAD_DIR/$archive_name"
base=$(node_download_base)
url="$base/$archive_name"
platform=$(node_platform)
source_kind=$(printf '%s' "$platform" | cut -d'|' -f1)
shasums="$GLNER_DOWNLOAD_DIR/node-v${GLNER_NODE_VERSION}-${source_kind}-SHASUMS256.txt"
shasums_url="$base/SHASUMS256.txt"

if [ "${1:-}" = "--dry-run" ]; then
    echo "Node.js $GLNER_NODE_VERSION"
    echo "Platform: $platform"
    echo "URL:      $url"
    echo "Cache:    $archive"
    exit 0
fi

if [ ! -s "$archive" ]; then
    download_file "$url" "$archive"
else
    echo "Already downloaded:"
    echo "  $archive"
fi

if [ ! -s "$shasums" ]; then
    download_file "$shasums_url" "$shasums"
else
    echo "Already downloaded checksum manifest:"
    echo "  $shasums"
fi

verify_from_shasums "$archive" "$shasums"
echo "Downloaded Node.js archive:"
echo "  $archive"
