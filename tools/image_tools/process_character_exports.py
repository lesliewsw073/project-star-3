#!/usr/bin/env python3
"""從 cursor_png 原圖產出 avatar / portrait。

## 生成規則（process_character_exports）

**來源**
- 目錄：`cursor_png/`
- 檔名：`{character_id}.png`（例 `artist_006.png`、`npc_shopkeeper_01.png`）
- 僅處理根目錄 PNG，不含 `processed/` 子目錄

**去背**
- 四角泛洪去除 #FFFFFF 白底（tolerance=28）
- 保留制服白條等內部白色
- 邊緣半透明像素一併清除

**輸出命名**（對齊 CharacterVisualPaths.gd）
- 頭像：`processed/avatar/{id}_avatar.png` → 512×512 RGBA
- 立繪：`processed/portrait/{id}_portrait.png` → 900×1400 RGBA

**頭像（與立绘規則分開）**
- 取 bbox 上方半身裁成正方形（水平置中），保留髮頂／帽子餘量
- 等比放大至 512×512，四周留約 7% 透明邊距（不貼邊、不裁頭髮）
- 水平微調可後續用 `AVATAR_HORIZONTAL_OFFSET[id]`

**立绘（全身構圖，與頭像不同）**
- 人物高度 = 畫布高 × 82%，底邊距 5%，水平預設置中
- 寬圖左緣被裁：`PORTRAIT_HORIZONTAL_OFFSET[id]` 正數右移（artist_001=50）

**後處理**
- avatar：pngquant + optipng
- portrait：不跑 pngquant（保透明与细节）
"""

from __future__ import annotations

import subprocess
from collections import deque
from pathlib import Path

import cv2
import numpy as np
from PIL import Image

SRC_DIR = Path("/Users/luke/project-star-3/cursor_png")
OUT_AVATAR = SRC_DIR / "processed" / "avatar"
OUT_PORTRAIT = SRC_DIR / "processed" / "portrait"

AVATAR_SIZE = 512
PORTRAIT_SIZE = (900, 1400)

# 統一構圖（立绘；頭像見 make_avatar）
PORTRAIT_BODY_HEIGHT_RATIO = 0.82
PORTRAIT_BOTTOM_MARGIN_RATIO = 0.05
# 頭像：上方半身裁切 + 留邊放大（與立绘分開）
AVATAR_MARGIN_RATIO = 0.07
AVATAR_HEAD_CROP_HEIGHT_RATIO = 0.50
AVATAR_HORIZONTAL_OFFSET: dict[str, int] = {
    "artist_001": 48,  # 脸偏左（吉他拉偏整体质心）→ 右移
    "artist_006": -38,
    "artist_007": -16,
    "npc_shopkeeper_01": -40,
}

# 立绘水平微调：正数 = 右移（宽图左缘被裁时用来露出吉他等）
PORTRAIT_HORIZONTAL_OFFSET: dict[str, int] = {
    "artist_001": 50,
}


def flood_remove_white(img: Image.Image, tolerance: int = 28) -> Image.Image:
    data = np.array(img.convert("RGBA"))
    rgb = data[:, :, :3]
    alpha = data[:, :, 3].copy()
    h, w = rgb.shape[:2]

    def bg_like(r: int, g: int, b: int) -> bool:
        return int(r) >= 255 - tolerance and int(g) >= 255 - tolerance and int(b) >= 255 - tolerance

    visited = np.zeros((h, w), dtype=bool)
    bg_mask = np.zeros((h, w), dtype=bool)
    q: deque[tuple[int, int]] = deque()

    for x in range(w):
        for y in (0, h - 1):
            if bg_like(*rgb[y, x]) and not visited[y, x]:
                visited[y, x] = True
                bg_mask[y, x] = True
                q.append((y, x))
    for y in range(h):
        for x in (0, w - 1):
            if bg_like(*rgb[y, x]) and not visited[y, x]:
                visited[y, x] = True
                bg_mask[y, x] = True
                q.append((y, x))

    while q:
        y, x = q.popleft()
        for ny, nx in ((y - 1, x), (y + 1, x), (y, x - 1), (y, x + 1)):
            if 0 <= ny < h and 0 <= nx < w and not visited[ny, nx]:
                if bg_like(*rgb[ny, nx]):
                    visited[ny, nx] = True
                    bg_mask[ny, nx] = True
                    q.append((ny, nx))

    # 邊緣抗鋸齒：貼近背景的半透明像素一併清掉
    edge = cv2.dilate(bg_mask.astype(np.uint8), np.ones((3, 3), np.uint8), iterations=2).astype(bool)
    near_white = np.min(rgb, axis=2) >= 255 - tolerance - 8
    alpha[edge & near_white] = 0
    alpha[bg_mask] = 0
    data[:, :, 3] = alpha
    return Image.fromarray(data)


def content_bbox(img: Image.Image) -> tuple[int, int, int, int]:
    alpha = np.array(img.split()[-1])
    ys, xs = np.where(alpha > 16)
    if len(xs) == 0:
        w, h = img.size
        return 0, 0, w, h
    return int(xs.min()), int(ys.min()), int(xs.max()) + 1, int(ys.max()) + 1


def place_on_canvas(
    content: Image.Image,
    canvas_size: tuple[int, int],
    *,
    target_height: int,
    bottom_margin: int | None = None,
    top_margin: int | None = None,
    horizontal_offset: int = 0,
) -> Image.Image:
    """依目標高度等比縮放，水平置中（可加 horizontal_offset 右移）；底邊或頂邊對齊固定邊距。"""
    cw, ch = canvas_size
    w, h = content.size
    if h <= 0 or w <= 0:
        return Image.new("RGBA", canvas_size, (0, 0, 0, 0))

    scale = target_height / h
    nw = max(1, int(w * scale))
    nh = max(1, int(h * scale))
    resized = content.resize((nw, nh), Image.Resampling.LANCZOS)
    canvas = Image.new("RGBA", canvas_size, (0, 0, 0, 0))
    x = (cw - nw) // 2 + horizontal_offset
    if nw > cw:
        x = max(cw - nw, min(0, x))
    else:
        x = max(0, min(cw - nw, x))
    if bottom_margin is not None:
        y = ch - bottom_margin - nh
    elif top_margin is not None:
        y = top_margin
    else:
        y = (ch - nh) // 2
    canvas.paste(resized, (x, y), resized)
    return canvas


def crop_avatar_bust(body: Image.Image) -> Image.Image:
    """取 bbox 上方正方形半身（水平置中），含髮頂與肩，不含過多下半身。"""
    bw, bh = body.size
    side = min(bw, max(32, int(bh * AVATAR_HEAD_CROP_HEIGHT_RATIO)))
    left = max(0, (bw - side) // 2)
    return body.crop((left, 0, left + side, min(side, bh)))


def make_avatar(content: Image.Image, horizontal_offset: int = 0) -> Image.Image:
    x0, y0, x1, y1 = content_bbox(content)
    body = content.crop((x0, y0, x1, y1))
    bust = crop_avatar_bust(body)

    margin = int(AVATAR_SIZE * AVATAR_MARGIN_RATIO)
    usable = AVATAR_SIZE - 2 * margin
    cw, ch = bust.size
    scale = min(usable / cw, usable / ch)
    nw = max(1, int(cw * scale))
    nh = max(1, int(ch * scale))
    resized = bust.resize((nw, nh), Image.Resampling.LANCZOS)

    canvas = Image.new("RGBA", (AVATAR_SIZE, AVATAR_SIZE), (0, 0, 0, 0))
    x = (AVATAR_SIZE - nw) // 2 + horizontal_offset
    x = max(0, min(AVATAR_SIZE - nw, x))
    y = (AVATAR_SIZE - nh) // 2
    canvas.paste(resized, (x, y), resized)
    return canvas


def make_portrait(content: Image.Image, horizontal_offset: int = 0) -> Image.Image:
    x0, y0, x1, y1 = content_bbox(content)
    body = content.crop((x0, y0, x1, y1))
    cw, ch = PORTRAIT_SIZE
    target_h = int(ch * PORTRAIT_BODY_HEIGHT_RATIO)
    bottom_margin = int(ch * PORTRAIT_BOTTOM_MARGIN_RATIO)
    return place_on_canvas(
        body,
        PORTRAIT_SIZE,
        target_height=target_h,
        bottom_margin=bottom_margin,
        horizontal_offset=horizontal_offset,
    )


def _prepare_for_pixel_sample(rgba: np.ndarray) -> np.ndarray:
    """硬透明边即可；不做高斯锐化（会产生中间色 → 看起来糊）。"""
    out = rgba.copy()
    out[:, :, 3] = np.where(out[:, :, 3] > 40, 255, 0).astype(np.uint8)
    return out


def _flatten_color_levels(grid: np.ndarray, levels: int) -> np.ndarray:
    """把极接近的颜色合并成平涂色块（戴夫每块区域颜色很平）。"""
    if levels < 2:
        return grid
    out = grid.copy()
    mask = out[:, :, 3] > 32
    step = 255.0 / (levels - 1)
    for ch in range(3):
        plane = out[:, :, ch].astype(np.float32)
        plane[mask] = np.round(plane[mask] / step) * step
        out[:, :, ch] = np.clip(plane, 0, 255).astype(np.uint8)
    return out


def _hard_alpha(rgba: np.ndarray) -> np.ndarray:
    out = rgba.copy()
    out[:, :, 3] = np.where(out[:, :, 3] > 32, 255, 0).astype(np.uint8)
    return out


def _block_mode_sample(rgba: np.ndarray, logical: int) -> np.ndarray:
    """每逻辑格取众数原色（不混色），保留硬边色块。"""
    h, w = rgba.shape[:2]
    bh, bw = h // logical, w // logical
    h2, w2 = bh * logical, bw * logical
    img = rgba[:h2, :w2]
    blocks = (
        img.reshape(logical, bh, logical, bw, 4)
        .transpose(0, 2, 1, 3, 4)
        .reshape(logical, logical, bh * bw, 4)
    )
    out = np.zeros((logical, logical, 4), dtype=np.uint8)
    for gy in range(logical):
        for gx in range(logical):
            patch = blocks[gy, gx]
            opaque = patch[patch[:, 3] > 32]
            if opaque.size == 0:
                continue
            colors, counts = np.unique(opaque[:, :3], axis=0, return_counts=True)
            out[gy, gx, :3] = colors[int(counts.argmax())]
            out[gy, gx, 3] = min(255, int(opaque[:, 3].max()) + 16)
    return out


def optimize_png(path: Path) -> None:
    subprocess.run(
        [
            "/opt/homebrew/bin/pngquant",
            "--force",
            "--skip-if-larger",
            "--quality=70-92",
            "--ext",
            ".png",
            str(path),
        ],
        check=False,
    )
    subprocess.run(["/opt/homebrew/bin/optipng", "-quiet", "-o5", str(path)], check=False)


def discover_sources() -> list[Path]:
    out: list[Path] = []
    for path in sorted(SRC_DIR.glob("*.png")):
        if path.parent != SRC_DIR:
            continue
        stem = path.stem
        if stem.startswith("artist_") or stem.startswith("npc_"):
            out.append(path)
    return out


def cleanup_stale_outputs() -> None:
    for folder in (OUT_AVATAR, OUT_PORTRAIT):
        if not folder.exists():
            continue
        for stale in folder.glob("*-fs8.png"):
            stale.unlink(missing_ok=True)


def process_one(src: Path) -> None:
    character_id = src.stem
    print(f"處理 {character_id} …")
    img = Image.open(src)
    cutout = flood_remove_white(img)

    avatar = make_avatar(cutout, AVATAR_HORIZONTAL_OFFSET.get(character_id, 0))
    portrait = make_portrait(cutout, PORTRAIT_HORIZONTAL_OFFSET.get(character_id, 0))

    avatar_path = OUT_AVATAR / f"{character_id}_avatar.png"
    portrait_path = OUT_PORTRAIT / f"{character_id}_portrait.png"

    avatar.save(avatar_path, format="PNG")
    portrait.save(portrait_path, format="PNG")

    optimize_png(avatar_path)

    for label, p in (("avatar", avatar_path), ("portrait", portrait_path)):
        w, h = Image.open(p).size
        kb = p.stat().st_size / 1024
        print(f"  {label}: {w}x{h}, {kb:.0f} KB → {p}")


def main() -> None:
    OUT_AVATAR.mkdir(parents=True, exist_ok=True)
    OUT_PORTRAIT.mkdir(parents=True, exist_ok=True)
    cleanup_stale_outputs()

    sources = discover_sources()
    if not sources:
        raise SystemExit(f"找不到來源：{SRC_DIR}/artist_*.png 或 npc_*.png")

    for src in sources:
        process_one(src)

    print("\n完成。")


if __name__ == "__main__":
    main()
