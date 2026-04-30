#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

usage() {
  cat <<EOF
Usage: scripts/build.sh [options]

Options:
  --arch <arch>           Target CPU: amd64, arm64, armhf, x64 (alias for amd64)
  --os <os>               Target OS:  linux, alpine, macos, windows
  --target <os-arch>      VS Code target directly (e.g. linux-arm64, alpine-x64,
                          darwin-arm64, win32-x64). Overrides --arch/--os.
  --with-vscode           Force rebuild of bundled VS Code even if already built
  --version <ver>         Version string embedded in the build (default: 0.0.0)
  --release-path <path>   Output directory for the release tree (default: release)
  -h, --help              Show this help

Examples:
  scripts/build.sh                          # native build for this host
  scripts/build.sh --arch amd64             # cross-compile for x86_64 linux
  scripts/build.sh --target alpine-arm64    # cross-compile for Alpine arm64
  scripts/build.sh --with-vscode            # force VS Code rebuild
EOF
}

WITH_VSCODE=0

while [ $# -gt 0 ]; do
  case "$1" in
    --arch)          ARCH="$2"; shift 2 ;;
    --os)            OS="$2"; shift 2 ;;
    --target)        VSCODE_TARGET="$2"; shift 2 ;;
    --with-vscode)   WITH_VSCODE=1; shift ;;
    --version)       VERSION="$2"; shift 2 ;;
    --release-path)  RELEASE_PATH="$2"; shift 2 ;;
    -h|--help)       usage; exit 0 ;;
    *) echo "[build] unknown option: $1" >&2; usage >&2; exit 2 ;;
  esac
done

# x64 is the Node-side name for amd64; let users pass either.
if [ "${ARCH-}" = "x64" ]; then ARCH=amd64; fi

[ -n "${ARCH-}" ] && export ARCH
[ -n "${OS-}" ] && export OS
[ -n "${VSCODE_TARGET-}" ] && export VSCODE_TARGET

# Reuse upstream OS/ARCH/VSCODE_TARGET detection. Honors anything we exported
# above; otherwise falls back to host detection.
# shellcheck source=../ci/lib.sh
source ./ci/lib.sh

VERSION="${VERSION:-0.0.0}"
export VERSION

VSCODE_BUILD_DIR="lib/vscode-reh-web-$VSCODE_TARGET"

echo "[build] target: OS=$OS ARCH=$ARCH VSCODE_TARGET=$VSCODE_TARGET"

if [ ! -d node_modules ]; then
  echo "[build] installing dependencies"
  npm install
fi

if [ "$WITH_VSCODE" = "1" ] || [ ! -f "$VSCODE_BUILD_DIR/out/server-main.js" ]; then
  echo "[build] building bundled VS Code into $VSCODE_BUILD_DIR (this takes a while)"
  npm run build:vscode
fi

echo "[build] building code-server"
npm run build

echo "[build] assembling runnable release tree -> $ROOT/$RELEASE_PATH"
npm run release

if [ ! -d "$RELEASE_PATH/node_modules" ]; then
  echo "[build] installing runtime dependencies into $RELEASE_PATH/"
  (cd "$RELEASE_PATH" && npm install --omit=dev --no-audit --no-fund)
fi

echo "[build] done -> $ROOT/$RELEASE_PATH/out/node/entry.js"
