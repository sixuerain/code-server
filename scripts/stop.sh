#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PID_FILE="$ROOT/scripts/.run/code-server.pid"

if [ ! -f "$PID_FILE" ]; then
  echo "[stop] no pid file ($PID_FILE); not running"
  exit 0
fi

PID="$(cat "$PID_FILE")"
if ! kill -0 "$PID" 2>/dev/null; then
  echo "[stop] pid $PID not alive; cleaning up"
  rm -f "$PID_FILE"
  exit 0
fi

echo "[stop] sending SIGTERM to $PID"
kill "$PID"

for _ in $(seq 1 20); do
  if ! kill -0 "$PID" 2>/dev/null; then
    rm -f "$PID_FILE"
    echo "[stop] stopped"
    exit 0
  fi
  sleep 0.5
done

echo "[stop] still alive; sending SIGKILL"
kill -9 "$PID" 2>/dev/null || true
rm -f "$PID_FILE"
echo "[stop] killed"
