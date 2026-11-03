#!/usr/bin/env bash
# Arranca el backend y la app Flutter en una sesión tmux.
# Uso: ./scripts/dev.sh [linux|chrome|<device>]
set -euo pipefail

if ! command -v tmux >/dev/null 2>&1; then
  echo "tmux no está instalado (sudo dnf install tmux)" >&2
  exit 1
fi

root=$(cd "$(dirname "$0")/.." && pwd)
dev=${1:-linux}
session=travelplan

if tmux has-session -t "$session" 2>/dev/null; then
  exec tmux attach -t "$session"
fi

tmux new-session -d -s "$session" -c "$root/backend" \
  'uv run fastapi dev src/backend/main.py'
tmux split-window -h -t "$session" -c "$root/frontend" \
  "fvm flutter run -d $dev"
tmux select-layout -t "$session" even-horizontal
tmux attach -t "$session" || true

if tmux has-session -t "$session" 2>/dev/null; then
  echo
  echo "La sesión '$session' sigue en marcha. Para pararla: just stop"
fi
