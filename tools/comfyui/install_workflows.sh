#!/usr/bin/env bash
# Copy project workflows into ComfyUI user workflow folder.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
COMFY_ROOT="${COMFY_ROOT:-/Users/luke/ComfyUI}"
DEST="${COMFY_ROOT}/user/default/workflows"

mkdir -p "${DEST}"
cp "${SCRIPT_DIR}/workflows/"*.json "${DEST}/"
echo "Installed workflows to ${DEST}:"
ls -1 "${DEST}"
