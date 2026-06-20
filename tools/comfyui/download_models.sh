#!/usr/bin/env bash
# Download a minimal SD 1.5 + pixel-art LoRA set for Mac M4 POC (~2.2 GB total).
set -euo pipefail

COMFY_ROOT="${COMFY_ROOT:-/Users/luke/ComfyUI}"
CHECKPOINT_DIR="${COMFY_ROOT}/models/checkpoints"
LORA_DIR="${COMFY_ROOT}/models/loras"

mkdir -p "${CHECKPOINT_DIR}" "${LORA_DIR}"

download_if_missing() {
  local url="$1"
  local dest="$2"
  if [[ -f "${dest}" ]]; then
    echo "skip (exists): $(basename "${dest}")"
    return 0
  fi

  local partial="${dest}.partial"
  local attempt=1
  local max_attempts=5

  while (( attempt <= max_attempts )); do
    echo "downloading (attempt ${attempt}/${max_attempts}): $(basename "${dest}")"
    if curl -L --fail --retry 5 --retry-delay 5 --continue-at - --progress-bar "${url}" -o "${partial}"; then
      mv "${partial}" "${dest}"
      return 0
    fi
    echo "download interrupted, will resume..." >&2
    attempt=$((attempt + 1))
    sleep 3
  done

  echo "failed after ${max_attempts} attempts: $(basename "${dest}")" >&2
  return 1
}

download_if_missing \
  "https://huggingface.co/Lykon/DreamShaper/resolve/main/DreamShaper_8_pruned.safetensors" \
  "${CHECKPOINT_DIR}/DreamShaper_8_pruned.safetensors"

download_if_missing \
  "https://huggingface.co/artificialguybr/pixelartredmond-1-5v-pixel-art-loras-for-sd-1-5/resolve/main/PixelArtRedmond15V-PixelArt-PIXARFK.safetensors" \
  "${LORA_DIR}/PixelArtRedmond15V-PixelArt-PIXARFK.safetensors"

echo
echo "Models ready:"
ls -lh "${CHECKPOINT_DIR}/DreamShaper_8_pruned.safetensors"
ls -lh "${LORA_DIR}/PixelArtRedmond15V-PixelArt-PIXARFK.safetensors"
