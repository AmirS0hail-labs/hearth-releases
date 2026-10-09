#!/bin/bash
# Hearth Installer — downloads a checksum-verified binary for your platform.
#
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/AmirS0hail-labs/hearth-releases/main/install.sh | bash
#
# The binary is not code-signed. The script checks SHA256SUMS and stops if it
# cannot verify the download.
#
#   HEARTH_REPO=owner/repo       GitHub repo that holds the releases
#   HEARTH_BASE_URL=https://...  Download from this base instead of GitHub
#                                (expects <base>/<version>/hearth-<os>-<arch>)
#   HEARTH_VERSION=vX.Y.Z        Pin a tag instead of the latest release
#   HEARTH_INSTALL_DIR=path      Install here instead of /usr/local/bin.
#                                The directory must already be on PATH.
set -euo pipefail

REPO="${HEARTH_REPO:-AmirS0hail-labs/hearth-releases}"

echo ""
echo "  Hearth Installer"
echo "  ----------------"
echo ""

on_path() {
    case ":${PATH}:" in
        *":$1:"*) return 0 ;;
        *) return 1 ;;
    esac
}

OS=$(uname -s | tr '[:upper:]' '[:lower:]')
ARCH=$(uname -m)
case "$ARCH" in
    x86_64)       ARCH="amd64" ;;
    arm64|aarch64) ARCH="arm64" ;;
    *)
        echo "  ✗ Unsupported architecture: ${ARCH}"
        echo "    Hearth publishes darwin/arm64, darwin/amd64, linux/amd64, and linux/arm64."
        exit 1
        ;;
esac

case "$OS" in
    darwin|linux) ;;
    *)
        echo "  ✗ Unsupported OS: ${OS}"
        echo "    Hearth supports macOS and Linux only."
        exit 1
        ;;
esac

echo "  Platform: ${OS}/${ARCH}"

if [ -n "${HEARTH_INSTALL_DIR:-}" ]; then
    INSTALL_DIR="${HEARTH_INSTALL_DIR}"
    if ! on_path "${INSTALL_DIR}"; then
        echo "  ✗ HEARTH_INSTALL_DIR ${INSTALL_DIR} is not on PATH."
        echo "    PATH=${PATH}"
        exit 1
    fi
elif [ "$OS" = "darwin" ] && on_path "/opt/homebrew/bin"; then
    INSTALL_DIR="/opt/homebrew/bin"
elif on_path "/usr/local/bin"; then
    INSTALL_DIR="/usr/local/bin"
else
    echo "  ✗ No install directory is on PATH."
    echo "    Expected /usr/local/bin, or /opt/homebrew/bin when that directory is already on PATH."
    echo "    PATH=${PATH}"
    exit 1
fi

BINARY_NAME="hearth-${OS}-${ARCH}"

if [ -n "${HEARTH_BASE_URL:-}" ]; then
    VERSION="${HEARTH_VERSION:-latest}"
    DOWNLOAD_URL="${HEARTH_BASE_URL%/}/${VERSION}/${BINARY_NAME}"
    CHECKSUM_URL="${HEARTH_BASE_URL%/}/${VERSION}/SHA256SUMS"
else
    if [ -n "${HEARTH_VERSION:-}" ]; then
        LATEST="$HEARTH_VERSION"
    else
        echo "  Fetching latest release..."
        LATEST=$(curl -fsSL "https://api.github.com/repos/${REPO}/releases/latest" | grep '"tag_name"' | head -1 | sed -E 's/.*"([^"]+)".*/\1/')
    fi

    if [ -z "${LATEST}" ]; then
        echo ""
        echo "  ✗ Could not find a Hearth release for ${REPO}."
        echo "    Check https://github.com/${REPO}/releases"
        echo "    Or set HEARTH_VERSION / HEARTH_BASE_URL."
        exit 1
    fi

    echo "  Version: ${LATEST}"
    DOWNLOAD_URL="https://github.com/${REPO}/releases/download/${LATEST}/${BINARY_NAME}"
    CHECKSUM_URL="https://github.com/${REPO}/releases/download/${LATEST}/SHA256SUMS"
fi

TMP_BIN="$(mktemp)"
TMP_SUMS="$(mktemp)"
cleanup() {
    rm -f "${TMP_BIN}" "${TMP_SUMS}"
}
trap cleanup EXIT

echo "  Downloading ${BINARY_NAME}..."
HTTP_CODE=$(curl -sSL -w "%{http_code}" -o "${TMP_BIN}" "${DOWNLOAD_URL}" || true)
if [ "${HTTP_CODE}" != "200" ]; then
    echo "  ✗ Download failed (HTTP ${HTTP_CODE})."
    echo "    URL: ${DOWNLOAD_URL}"
    echo "    There is no verified build for ${OS}/${ARCH} at that address."
    exit 1
fi

echo "  Downloading SHA256SUMS..."
CHECKSUM_HTTP=$(curl -sSL -w "%{http_code}" -o "${TMP_SUMS}" "${CHECKSUM_URL}" || true)
if [ "${CHECKSUM_HTTP}" != "200" ]; then
    echo "  ✗ SHA256SUMS is missing (HTTP ${CHECKSUM_HTTP})."
    echo "    URL: ${CHECKSUM_URL}"
    echo "    Refusing to install an unverified binary."
    exit 1
fi

EXPECTED=$(grep "${BINARY_NAME}" "${TMP_SUMS}" | awk '{print $1}' | head -1)
if [ -z "${EXPECTED}" ]; then
    echo "  ✗ SHA256SUMS has no entry for ${BINARY_NAME}."
    echo "    Refusing to install an unverified binary."
    exit 1
fi

if command -v sha256sum >/dev/null 2>&1; then
    ACTUAL=$(sha256sum "${TMP_BIN}" | awk '{print $1}')
elif command -v shasum >/dev/null 2>&1; then
    ACTUAL=$(shasum -a 256 "${TMP_BIN}" | awk '{print $1}')
else
    echo "  ✗ Neither sha256sum nor shasum is installed."
    echo "    Refusing to install an unverified binary."
    exit 1
fi

if [ "${ACTUAL}" != "${EXPECTED}" ]; then
    echo "  ✗ Checksum verification failed."
    echo "    Expected: ${EXPECTED}"
    echo "    Got:      ${ACTUAL}"
    exit 1
fi
echo "  ✓ Checksum verified"

chmod 755 "${TMP_BIN}"
if [ -w "${INSTALL_DIR}" ]; then
    mv "${TMP_BIN}" "${INSTALL_DIR}/hearth"
else
    echo "  ${INSTALL_DIR} is not writable. Asking sudo (password is read from the terminal)."
    if [ ! -e /dev/tty ]; then
        echo "  ✗ No terminal is available for sudo."
        echo "    Copy it yourself:"
        echo "    sudo install -m 755 <downloaded-file> ${INSTALL_DIR}/hearth"
        exit 1
    fi
    if ! sudo install -m 755 "${TMP_BIN}" "${INSTALL_DIR}/hearth" < /dev/tty; then
        echo "  ✗ Could not write ${INSTALL_DIR}/hearth."
        exit 1
    fi
fi

hash -r 2>/dev/null || true
if ! command -v hearth >/dev/null 2>&1; then
    echo "  ✗ Installed ${INSTALL_DIR}/hearth but 'hearth' is not on PATH."
    echo "    PATH=${PATH}"
    exit 1
fi

echo ""
echo "  ✓ Hearth installed to ${INSTALL_DIR}/hearth"
echo "  $(hearth version 2>/dev/null || true)"
echo ""
echo "  Get started:"
echo "    hearth up"
echo ""
