#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
RUN_DIR="$ROOT/scripts/.run"
PID_FILE="$RUN_DIR/code-server.pid"
LOG_FILE="$RUN_DIR/code-server.log"

if [ ! -f "$PID_FILE" ]; then
  echo "status : stopped (no pid file)"
  exit 1
fi

PID="$(cat "$PID_FILE")"
if ! kill -0 "$PID" 2>/dev/null; then
  echo "status : stopped (stale pid $PID)"
  exit 1
fi

echo "status : running"
echo "pid    : $PID"
echo "log    : $LOG_FILE"

if command -v ss >/dev/null 2>&1; then
  PORTS="$(ss -ltnp 2>/dev/null | awk -v pid="$PID" '$0 ~ "pid="pid"," {print $4}' | tr '\n' ' ')"
  [ -n "$PORTS" ] && echo "listen : $PORTS"
fi

ps -o pid,etime,rss,cmd -p "$PID" 2>/dev/null || true
