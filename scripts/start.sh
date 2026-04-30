#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
RUN_DIR="$ROOT/scripts/.run"
PID_FILE="$RUN_DIR/code-server.pid"
LOG_FILE="$RUN_DIR/code-server.log"
RELEASE_PATH="${RELEASE_PATH:-release}"
ENTRY="$ROOT/$RELEASE_PATH/out/node/entry.js"

HOST="${HOST:-127.0.0.1}"
PORT="${PORT:-8080}"
BIND_ADDR="${BIND_ADDR:-${HOST}:${PORT}}"
AUTH="${AUTH:-none}"

mkdir -p "$RUN_DIR"

if [ -f "$PID_FILE" ] && kill -0 "$(cat "$PID_FILE")" 2>/dev/null; then
  echo "[start] already running (pid $(cat "$PID_FILE"))"
  exit 0
fi
rm -f "$PID_FILE"

if [ ! -f "$ENTRY" ]; then
  echo "[start] $ENTRY not found -- run scripts/build.sh first" >&2
  exit 1
fi

echo "[start] bind=$BIND_ADDR auth=$AUTH log=$LOG_FILE"
cd "$ROOT"
# Unset VSCODE_IPC_HOOK_CLI so we start a fresh server instead of forwarding
# to an existing VS Code instance (which happens when launched from a VS Code
# integrated terminal).
nohup env -u VSCODE_IPC_HOOK_CLI node "$ENTRY" \
  --bind-addr "$BIND_ADDR" \
  --auth "$AUTH" \
  "$@" \
  >>"$LOG_FILE" 2>&1 &

echo $! >"$PID_FILE"
sleep 1

if ! kill -0 "$(cat "$PID_FILE")" 2>/dev/null; then
  echo "[start] failed to start -- see $LOG_FILE" >&2
  rm -f "$PID_FILE"
  tail -n 40 "$LOG_FILE" >&2 || true
  exit 1
fi

echo "[start] running (pid $(cat "$PID_FILE"))"
