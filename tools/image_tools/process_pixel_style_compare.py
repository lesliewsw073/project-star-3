#!/usr/bin/env python3
"""三套像素风格对比出图：戴夫 / 圣魔光石 / 星露谷。"""

from __future__ import annotations

from dataclasses import dataclass
from pathlib import Path

import cv2
import numpy as np
from PIL import Image

from process_character_exports import (
    PORTRAIT_BODY_HEIGHT_RATIO,
    PORTRAIT_BOTTOM_MARGIN_RATIO,
    PIXEL_WORK_SIZE,
    SRC_DIR,
    _block_mode_sample,
    _flatten_color_levels,
    _hard_alpha,
    _prepare_for_pixel_sample,
    content_bbox,
    flood_remove_white,
    place_on_canvas,
)

OUT_ROOT = SRC_DIR / "pixel_compare"
OUT_SIZE = 512

STYLES: dict[str, Path] = {
    "01_dave_the_diver": OUT_ROOT / "01_dave_the_diver",
    "02_fire_emblem_sacred_stones": OUT_ROOT / "02_fire_emblem_sacred_stones",
    "03_stardew_valley": OUT_ROOT / "03_stardew_valley",
}


@dataclass(frozen=True)
class PixelStyle:
    logical_grid: int
    color_levels: int
    outline: str  # none | hard | soft
    dither: bool
    face_grid_boost: float  # 脸部区域逻辑格加密倍数


DAVE = PixelStyle(logical_grid=56, color_levels=10, outline="none", dither=False, face_grid_boost=1.0)
FIRE_EMBLEM = PixelStyle(
    logical_grid=80, color_levels=9, outline="hard", dither=True, face_grid_boost=1.15
)
STARDEW = PixelStyle(
    logical_grid=72, color_levels=14, outline="soft", dither=False, face_grid_boost=1.08
)


def _add_outline_logical(
    grid: np.ndarray,
    *,
    mode: str,
    hard_rgb: tuple[int, int, int] = (28, 20, 36),
) -> np.ndarray:
    out = grid.copy()
    h, w = grid.shape[:2]
    opaque = grid[:, :, 3] > 32
    for y in range(h):
        for x in range(w):
            if opaque[y, x]:
                continue
            touch = False
            neighbor_rgb = None
            for ny, nx in ((y - 1, x), (y + 1, x), (y, x - 1), (y, x + 1)):
                if 0 <= ny < h and 0 <= nx < w and opaque[ny, nx]:
                    touch = True
                    neighbor_rgb = grid[ny, nx, :3]
                    break
            if not touch:
                continue
            if mode == "hard":
                out[y, x, :3] = np.array(hard_rgb, dtype=np.uint8)
                out[y, x, 3] = 255
            elif mode == "soft" and neighbor_rgb is not None:
                soft = np.clip(neighbor_rgb.astype(np.float32) * 0.72, 0, 255).astype(np.uint8)
                out[y, x, :3] = soft
                out[y, x, 3] = 255
    return out


def _apply_fe_dither(grid: np.ndarray) -> np.ndarray:
    """圣魔光石式：下半身阴影区加有序抖动，模拟 GBA dither。"""
    out = grid.copy()
    h, w = grid.shape[:2]
    start_y = int(h * 0.38)
    mask = out[:, :, 3] > 32
    for y in range(start_y, h):
        for x in range(w):
            if not mask[y, x]:
                continue
            base = out[y, x, :3].astype(np.float32)
            darker = np.clip(base * 0.82, 0, 255)
            if (x + y) % 2 == 0:
                out[y, x, :3] = darker.astype(np.uint8)
    return out


def _sample_with_face_boost(rgba: np.ndarray, style: PixelStyle) -> np.ndarray:
    """身体用主逻辑格；脸上半区用更密网格，便于辨认五官。"""
    base = _block_mode_sample(rgba, style.logical_grid)
    if style.face_grid_boost <= 1.001:
        return base

    face_grid = max(style.logical_grid + 4, int(style.logical_grid * style.face_grid_boost))
    face_rows = max(8, int(style.logical_grid * 0.46))
    h, w = rgba.shape[:2]
    row_h = h // style.logical_grid
    cut_y = min(h, face_rows * row_h)
    if cut_y <= row_h * 2:
        return base

    face_src = rgba[:cut_y, :]
    face_logical = min(face_grid, cut_y // max(1, cut_y // face_grid))
    face_logical = max(style.logical_grid, face_logical)
    face_sample = _block_mode_sample(face_src, face_logical)

    # 把脸区样本映射回 base 网格的上半段
    out = base.copy()
    face_rows_out = face_rows
    for gy in range(face_rows_out):
        src_y = min(face_sample.shape[0] - 1, int(gy * face_sample.shape[0] / face_rows_out))
        for gx in range(out.shape[1]):
            src_x = min(face_sample.shape[1] - 1, int(gx * face_sample.shape[1] / out.shape[1]))
            if face_sample[src_y, src_x, 3] > 32:
                out[gy, gx] = face_sample[src_y, src_x]
    return out


def render_pixel_style(content: Image.Image, style: PixelStyle) -> Image.Image:
    x0, y0, x1, y1 = content_bbox(content)
    body = content.crop((x0, y0, x1, y1))
    target_h = int(PIXEL_WORK_SIZE * PORTRAIT_BODY_HEIGHT_RATIO)
    bottom_margin = int(PIXEL_WORK_SIZE * PORTRAIT_BOTTOM_MARGIN_RATIO)
    framed = place_on_canvas(
        body,
        (PIXEL_WORK_SIZE, PIXEL_WORK_SIZE),
        target_height=target_h,
        bottom_margin=bottom_margin,
    )

    rgba = _prepare_for_pixel_sample(np.array(framed.convert("RGBA")))
    logical = _sample_with_face_boost(rgba, style)
    logical = _flatten_color_levels(logical, style.color_levels)

    if style.dither:
        logical = _apply_fe_dither(logical)
    if style.outline == "hard":
        logical = _add_outline_logical(logical, mode="hard")
    elif style.outline == "soft":
        logical = _add_outline_logical(logical, mode="soft")

    pixel = cv2.resize(logical, (OUT_SIZE, OUT_SIZE), interpolation=cv2.INTER_NEAREST)
    return Image.fromarray(_hard_alpha(pixel))


def main() -> None:
    for folder in STYLES.values():
        folder.mkdir(parents=True, exist_ok=True)

    sources = sorted(p for p in SRC_DIR.glob("artist_*.png") if p.parent == SRC_DIR)
    if not sources:
        raise SystemExit(f"找不到來源：{SRC_DIR}/artist_*.png")

    style_map = {
        "01_dave_the_diver": DAVE,
        "02_fire_emblem_sacred_stones": FIRE_EMBLEM,
        "03_stardew_valley": STARDEW,
    }

    for src in sources:
        artist_id = src.stem
        cutout = flood_remove_white(Image.open(src))
        print(f"出图 {artist_id} …")
        for key, folder in STYLES.items():
            img = render_pixel_style(cutout, style_map[key])
            out_path = folder / f"{artist_id}_512.png"
            img.save(out_path, format="PNG")
            print(f"  → {out_path.relative_to(SRC_DIR)}")

    print("\n完成。请打开 cursor_png/pixel_compare/ 对比三套风格。")


if __name__ == "__main__":
    main()
