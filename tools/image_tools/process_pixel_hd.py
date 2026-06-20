#!/usr/bin/env python3
"""
HD 像素极限批处理：对齐用户自研参考（1024、细格、描边、平涂色块、脸可辨）。
"""

from __future__ import annotations

from pathlib import Path

import cv2
import numpy as np
from PIL import Image

from process_character_exports import (
    PORTRAIT_BODY_HEIGHT_RATIO,
    PORTRAIT_BOTTOM_MARGIN_RATIO,
    SRC_DIR,
    _block_mode_sample,
    _hard_alpha,
    content_bbox,
    flood_remove_white,
    place_on_canvas,
)

OUT_DIR = SRC_DIR / "pixel_hd"
OUT_SIZE = 1024
WORK_SIZE = 2048
LOGICAL_GRID = 200  # 1024÷200 ≈ 5px/块，接近参考图颗粒
MAX_COLORS = 112
BILATERAL_D = 9
BILATERAL_SIGMA = 48
OUTLINE_RGB = (22, 14, 30)


def _prepare_rgba(rgba: np.ndarray) -> np.ndarray:
    out = rgba.copy()
    out[:, :, 3] = np.where(out[:, :, 3] > 40, 255, 0).astype(np.uint8)
    rgb = out[:, :, :3].astype(np.float32)
    alpha = out[:, :, 3] > 0
    if alpha.any():
        smooth = cv2.bilateralFilter(
            out[:, :, :3],
            d=BILATERAL_D,
            sigmaColor=BILATERAL_SIGMA,
            sigmaSpace=BILATERAL_SIGMA,
        )
        out[:, :, :3] = np.where(alpha[:, :, None], smooth, rgb).astype(np.uint8)
    return out


def _quantize_logical(grid: np.ndarray, max_colors: int) -> np.ndarray:
    rgb_img = Image.fromarray(grid[:, :, :3])
    alpha = grid[:, :, 3]
    q = rgb_img.quantize(colors=max_colors, method=Image.Quantize.MEDIANCUT)
    pal = np.array(q.convert("RGB"))
    out = grid.copy()
    out[:, :, :3] = pal
    out[:, :, 3] = alpha
    return out


def _apply_outlines(grid: np.ndarray) -> np.ndarray:
    """仅外轮廓描边；避免内线覆盖五官。"""
    out = grid.copy()
    h, w = grid.shape[:2]
    opaque = grid[:, :, 3] > 32

    for y in range(h):
        for x in range(w):
            if opaque[y, x]:
                continue
            for ny, nx in ((y - 1, x), (y + 1, x), (y, x - 1), (y, x + 1)):
                if 0 <= ny < h and 0 <= nx < w and opaque[ny, nx]:
                    out[y, x, :3] = np.array(OUTLINE_RGB, dtype=np.uint8)
                    out[y, x, 3] = 255
                    break
    return out


def _boost_face_band(logical_grid: np.ndarray, rgba_work: np.ndarray, logical: int) -> np.ndarray:
    """脸上半区用更密网格重采样，保留眼/唇。"""
    face_rows = max(10, int(logical * 0.42))
    row_px = rgba_work.shape[0] // logical
    cut = min(rgba_work.shape[0], face_rows * row_px)
    if cut < row_px * 3:
        return logical_grid

    face_grid = min(logical + 48, 256)
    face = _block_mode_sample(rgba_work[:cut, :], face_grid)
    out = logical_grid.copy()
    fh, fw = face.shape[:2]
    for gy in range(face_rows):
        sy = min(fh - 1, int(gy * fh / face_rows))
        for gx in range(logical):
            sx = min(fw - 1, int(gx * fw / logical))
            if face[sy, sx, 3] > 32:
                out[gy, gx] = face[sy, sx]
    return out


def render_hd_pixel(content: Image.Image, *, white_bg: bool = True) -> Image.Image:
    x0, y0, x1, y1 = content_bbox(content)
    body = content.crop((x0, y0, x1, y1))
    target_h = int(WORK_SIZE * PORTRAIT_BODY_HEIGHT_RATIO)
    bottom_margin = int(WORK_SIZE * PORTRAIT_BOTTOM_MARGIN_RATIO)
    framed = place_on_canvas(
        body,
        (WORK_SIZE, WORK_SIZE),
        target_height=target_h,
        bottom_margin=bottom_margin,
    )

    rgba = _prepare_rgba(np.array(framed.convert("RGBA")))
    logical = _block_mode_sample(rgba, LOGICAL_GRID)
    logical = _boost_face_band(logical, rgba, LOGICAL_GRID)
    logical = _quantize_logical(logical, MAX_COLORS)
    logical = _apply_outlines(logical)

    pixel = cv2.resize(logical, (OUT_SIZE, OUT_SIZE), interpolation=cv2.INTER_NEAREST)
    pixel = _hard_alpha(pixel)

    if white_bg:
        bg = np.full((OUT_SIZE, OUT_SIZE, 3), 255, dtype=np.uint8)
        a = pixel[:, :, 3:4].astype(np.float32) / 255.0
        rgb = pixel[:, :, :3].astype(np.float32)
        comp = (rgb * a + bg * (1.0 - a)).astype(np.uint8)
        return Image.fromarray(comp)

    return Image.fromarray(pixel)


def main() -> None:
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    sources = sorted(p for p in SRC_DIR.glob("artist_*.png") if p.parent == SRC_DIR)
    if not sources:
        raise SystemExit(f"找不到來源：{SRC_DIR}/artist_*.png")

    for src in sources:
        cut = flood_remove_white(Image.open(src))
        img = render_hd_pixel(cut, white_bg=True)
        out = OUT_DIR / f"{src.stem}_pixel_hd_1024.png"
        img.save(out, format="PNG", optimize=True)
        kb = out.stat().st_size / 1024
        print(f"{out.name}  {OUT_SIZE}x{OUT_SIZE}  {kb:.0f} KB")

    print(f"\n完成 → {OUT_DIR}")


if __name__ == "__main__":
    main()
