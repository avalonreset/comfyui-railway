#!/usr/bin/env bash
set -euo pipefail

COMFYUI_DIR="${COMFYUI_DIR:-/root/ComfyUI}"
COMFYUI_INTERNAL_PORT="${COMFYUI_INTERNAL_PORT:-8188}"
EXTERNAL_PORT="${PORT:-8188}"

EXTRA_ARGS="${CLI_ARGS:-${COMFYUI_ARGS:-}}"

cd "$COMFYUI_DIR"

if [ "$EXTERNAL_PORT" = "$COMFYUI_INTERNAL_PORT" ]; then
  exec python3.11 -u /root/ComfyUI/main.py --cpu --listen 0.0.0.0 --port "$COMFYUI_INTERNAL_PORT" $EXTRA_ARGS
fi

python3.11 -u /root/ComfyUI/main.py --cpu --listen 127.0.0.1 --port "$COMFYUI_INTERNAL_PORT" $EXTRA_ARGS &
comfy_pid="$!"

exec socat "TCP-LISTEN:${EXTERNAL_PORT},fork,reuseaddr" "TCP:127.0.0.1:${COMFYUI_INTERNAL_PORT}"

