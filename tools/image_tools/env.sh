# shellcheck disable=SC2034
# 使用前：source tools/image_tools/env.sh
export PATH="/opt/homebrew/bin:${PATH}"
export MAGICK_HOME="/opt/homebrew/opt/imagemagick"
export DYLD_LIBRARY_PATH="/opt/homebrew/lib:${DYLD_LIBRARY_PATH:-}"
IMAGE_TOOLS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
alias imgtools-python="${IMAGE_TOOLS_DIR}/.venv/bin/python"
