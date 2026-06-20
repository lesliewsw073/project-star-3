#!/usr/bin/env bash
# Start ComfyUI on localhost:8188 (MPS / Apple Silicon).
set -euo pipefail

COMFY_ROOT="${COMFY_ROOT:-/Users/luke/ComfyUI}"
PYTHON="${COMFY_ROOT}/.venv/bin/python"

if [[ ! -x "${PYTHON}" ]]; then
  echo "ComfyUI venv not found: ${PYTHON}" >&2
  exit 1
fi

cd "${COMFY_ROOT}"
exec "${PYTHON}" main.py \
  --listen 127.0.0.1 \
  --port 8188 \
  --disable-auto-launch \
  --enable-manager
