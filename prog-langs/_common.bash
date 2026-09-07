#!/usr/bin/env bash
# Shared helpers for the glner-dev provisioning scripts.

set -o pipefail

GLNER_PROG_LANGS_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
GLNER_DEV_ROOT=$(cd -- "$GLNER_PROG_LANGS_DIR/.." && pwd -P)
# shellcheck source=../versions.env
source "$GLNER_DEV_ROOT/versions.env"

GLNER_DOWNLOAD_DIR="$GLNER_PROG_LANGS_DIR/downloads"
GLNER_INSTALL_DIR="$GLNER_PROG_LANGS_DIR/installed"
GLNER_PYTHON_VENV_DIR="$GLNER_PROG_LANGS_DIR/$GLNER_PYTHON_VENV_NAME"

mkdir -p "$GLNER_DOWNLOAD_DIR" "$GLNER_INSTALL_DIR"

fail() {
    echo "ERROR: $*" >&2
    return 1 2>/dev/null || exit 1
}

have_command() {
    command -v "$1" >/dev/null 2>&1
}

detect_os() {
    if [ -n "${GLNER_DEV_OS_OVERRIDE:-}" ]; then
        printf '%s\n' "$GLNER_DEV_OS_OVERRIDE"
        return
    fi
    case "$(uname -s 2>/dev/null || true)" in
        Linux) printf '%s\n' linux ;;
        Darwin) printf '%s\n' macos ;;
        MINGW*|MSYS*|CYGWIN*) printf '%s\n' windows ;;
        *) fail "Unsupported operating system: $(uname -s 2>/dev/null || echo unknown)" ;;
    esac
}

detect_arch() {
    if [ -n "${GLNER_DEV_ARCH_OVERRIDE:-}" ]; then
        printf '%s\n' "$GLNER_DEV_ARCH_OVERRIDE"
        return
    fi
    case "$(uname -m 2>/dev/null || true)" in
        x86_64|amd64) printf '%s\n' x64 ;;
        aarch64|arm64) printf '%s\n' arm64 ;;
        *) fail "Unsupported architecture: $(uname -m 2>/dev/null || echo unknown)" ;;
    esac
}

download_file() {
    url=$1
    destination=$2
    tmp="${destination}.part"

    mkdir -p "$(dirname -- "$destination")"
    rm -f "$tmp"

    echo "Downloading:"
    echo "  $url"
    echo "To:"
    echo "  $destination"

    if have_command curl; then
        curl -fL --retry 3 --retry-delay 2 -o "$tmp" "$url"
    elif have_command wget; then
        wget -O "$tmp" "$url"
    else
        fail "Neither curl nor wget is available"
    fi
    mv -f "$tmp" "$destination"
}

sha256_file() {
    file=$1
    if have_command sha256sum; then
        sha256sum "$file" | awk '{print $1}'
    elif have_command shasum; then
        shasum -a 256 "$file" | awk '{print $1}'
    elif have_command certutil; then
        certutil -hashfile "$file" SHA256 2>/dev/null | awk 'NR==2 {gsub(/[[:space:]]/, ""); print tolower($0)}'
    else
        return 1
    fi
}

verify_from_shasums() {
    archive=$1
    shasums=$2
    filename=$(basename -- "$archive")
    expected=$(awk -v name="$filename" '$2 == name || $2 == "*" name {print tolower($1); exit}' "$shasums")
    if [ -z "$expected" ]; then
        fail "No checksum found for $filename in $shasums"
    fi
    if ! actual=$(sha256_file "$archive"); then
        echo "Warning: no SHA-256 command available; skipping checksum verification." >&2
        return 0
    fi
    actual=$(printf '%s' "$actual" | tr '[:upper:]' '[:lower:]')
    if [ "$actual" != "$expected" ]; then
        fail "SHA-256 mismatch for $archive"
    fi
    echo "SHA-256 verified: $filename"
}

version_lt() {
    # Usage: version_lt 2.17 2.28
    awk -v A="$1" -v B="$2" 'BEGIN {
        n=split(A,a,"."); m=split(B,b,"."); max=(n>m?n:m);
        for (i=1;i<=max;i++) { ai=(i<=n?a[i]+0:0); bi=(i<=m?b[i]+0:0); if (ai<bi) exit 0; if (ai>bi) exit 1 }
        exit 1
    }'
}

linux_libc_kind() {
    if [ -n "${GLNER_DEV_LIBC_OVERRIDE:-}" ]; then
        printf '%s\n' "$GLNER_DEV_LIBC_OVERRIDE"
        return
    fi
    if ldd /bin/sh 2>&1 | grep -qi musl; then
        printf '%s\n' musl
    else
        printf '%s\n' glibc
    fi
}

linux_glibc_version() {
    if [ -n "${GLNER_DEV_GLIBC_OVERRIDE:-}" ]; then
        printf '%s\n' "$GLNER_DEV_GLIBC_OVERRIDE"
        return
    fi
    if have_command getconf; then
        getconf GNU_LIBC_VERSION 2>/dev/null | awk '{print $2}'
    else
        ldd --version 2>&1 | head -1 | grep -Eo '[0-9]+\.[0-9]+' | tail -1
    fi
}

python_target_triple() {
    os=$(detect_os) || return 1
    arch=$(detect_arch) || return 1
    case "$os:$arch" in
        linux:x64) printf '%s\n' x86_64-unknown-linux-gnu ;;
        linux:arm64) printf '%s\n' aarch64-unknown-linux-gnu ;;
        macos:x64) printf '%s\n' x86_64-apple-darwin ;;
        macos:arm64) printf '%s\n' aarch64-apple-darwin ;;
        windows:x64) printf '%s\n' x86_64-pc-windows-msvc ;;
        windows:arm64) printf '%s\n' aarch64-pc-windows-msvc ;;
        *) fail "Unsupported Python platform: $os/$arch" ;;
    esac
}

python_archive_name() {
    target=$(python_target_triple) || return 1
    printf 'cpython-%s+%s-%s-install_only_stripped.tar.gz\n' \
        "$GLNER_PYTHON_VERSION" "$GLNER_PYTHON_BUILD_RELEASE" "$target"
}

python_install_path() {
    target=$(python_target_triple) || return 1
    printf '%s/python-%s-%s\n' "$GLNER_INSTALL_DIR" "$GLNER_PYTHON_VERSION" "$target"
}

python_base_executable() {
    install=$(python_install_path) || return 1
    os=$(detect_os) || return 1
    if [ "$os" = windows ]; then
        printf '%s/python.exe\n' "$install"
    else
        printf '%s/bin/python3\n' "$install"
    fi
}

python_venv_executable() {
    os=$(detect_os) || return 1
    if [ "$os" = windows ]; then
        printf '%s/Scripts/python.exe\n' "$GLNER_PYTHON_VENV_DIR"
    else
        printf '%s/bin/python\n' "$GLNER_PYTHON_VENV_DIR"
    fi
}

python_venv_activate() {
    os=$(detect_os) || return 1
    if [ "$os" = windows ]; then
        printf '%s/Scripts/activate\n' "$GLNER_PYTHON_VENV_DIR"
    else
        printf '%s/bin/activate\n' "$GLNER_PYTHON_VENV_DIR"
    fi
}

node_platform() {
    os=$(detect_os) || return 1
    arch=$(detect_arch) || return 1

    case "$os:$arch" in
        windows:x64) printf '%s|%s|%s\n' official win-x64 zip ;;
        windows:arm64) printf '%s|%s|%s\n' official win-arm64 zip ;;
        macos:x64) printf '%s|%s|%s\n' official darwin-x64 tar.gz ;;
        macos:arm64) printf '%s|%s|%s\n' official darwin-arm64 tar.gz ;;
        linux:x64)
            kind=$(linux_libc_kind)
            if [ "$kind" = musl ]; then
                printf '%s|%s|%s\n' unofficial linux-x64-musl tar.gz
            else
                glibc=$(linux_glibc_version)
                if [ -n "$glibc" ] && version_lt "$glibc" 2.28; then
                    # Node 22 still has an unofficial glibc 2.17 build. This is
                    # why glner-dev pins Node 22 instead of Node 24.
                    printf '%s|%s|%s\n' unofficial linux-x64-glibc-217 tar.gz
                else
                    printf '%s|%s|%s\n' official linux-x64 tar.gz
                fi
            fi
            ;;
        linux:arm64)
            kind=$(linux_libc_kind)
            if [ "$kind" = musl ]; then
                printf '%s|%s|%s\n' unofficial linux-arm64-musl tar.gz
            else
                glibc=$(linux_glibc_version)
                if [ -n "$glibc" ] && version_lt "$glibc" 2.28; then
                    fail "Node $GLNER_NODE_VERSION has no glibc-2.17 ARM64 build in the supported mapping"
                fi
                printf '%s|%s|%s\n' official linux-arm64 tar.gz
            fi
            ;;
        *) fail "Unsupported Node.js platform: $os/$arch" ;;
    esac
}

node_archive_name() {
    platform=$(node_platform) || return 1
    tag=$(printf '%s' "$platform" | cut -d'|' -f2)
    ext=$(printf '%s' "$platform" | cut -d'|' -f3)
    printf 'node-v%s-%s.%s\n' "$GLNER_NODE_VERSION" "$tag" "$ext"
}

node_download_base() {
    platform=$(node_platform) || return 1
    source=$(printf '%s' "$platform" | cut -d'|' -f1)
    if [ "$source" = official ]; then
        printf 'https://nodejs.org/dist/v%s\n' "$GLNER_NODE_VERSION"
    else
        printf 'https://unofficial-builds.nodejs.org/download/release/v%s\n' "$GLNER_NODE_VERSION"
    fi
}

node_install_path() {
    platform=$(node_platform) || return 1
    tag=$(printf '%s' "$platform" | cut -d'|' -f2)
    printf '%s/node-%s-%s\n' "$GLNER_INSTALL_DIR" "$GLNER_NODE_VERSION" "$tag"
}

node_executable() {
    install=$(node_install_path) || return 1
    os=$(detect_os) || return 1
    if [ "$os" = windows ]; then
        printf '%s/node.exe\n' "$install"
    else
        printf '%s/bin/node\n' "$install"
    fi
}
