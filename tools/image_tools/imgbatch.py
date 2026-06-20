#!/usr/bin/env python3
"""批量圖片：去白底、縮放、像素復古化。"""

from __future__ import annotations

import argparse
import sys
from pathlib import Path

from PIL import Image
import cv2
import numpy as np

IMAGE_SUFFIXES = {".png", ".jpg", ".jpeg", ".webp", ".bmp", ".gif", ".tiff", ".tif"}


def iter_images(inputs: list[str], recursive: bool) -> list[Path]:
    paths: list[Path] = []
    for raw in inputs:
        p = Path(raw)
        if p.is_file():
            if p.suffix.lower() in IMAGE_SUFFIXES:
                paths.append(p)
            continue
        if not p.is_dir():
            raise SystemExit(f"找不到：{p}")
        pattern = "**/*" if recursive else "*"
        for child in sorted(p.glob(pattern)):
            if child.is_file() and child.suffix.lower() in IMAGE_SUFFIXES:
                paths.append(child)
    if not paths:
        raise SystemExit("沒有找到可處理的圖片。")
    return paths


def output_path(src: Path, out_dir: Path | None, suffix: str) -> Path:
    base = out_dir if out_dir else src.parent
    return base / f"{src.stem}{suffix}{src.suffix if src.suffix.lower() == '.png' else '.png'}"


def remove_white_background(
    src: Path,
    dst: Path,
    *,
    threshold: int,
    fuzz: int,
) -> None:
    img = Image.open(src).convert("RGBA")
    data = np.array(img)
    rgb = data[:, :, :3].astype(np.int16)
    white = np.array([255, 255, 255], dtype=np.int16)
    dist = np.max(np.abs(rgb - white), axis=2)
    alpha = data[:, :, 3].copy()
    mask = dist <= fuzz
    if threshold < 255:
        near_white = np.min(rgb, axis=2) >= threshold
        mask &= near_white
    alpha[mask] = 0
    data[:, :, 3] = alpha
    Image.fromarray(data).save(dst, format="PNG")


def resize_image(src: Path, dst: Path, *, width: int | None, height: int | None, keep_aspect: bool) -> None:
    img = Image.open(src)
    w, h = img.size
    if width and height:
        target = (width, height)
    elif width:
        target = (width, int(h * width / w)) if keep_aspect else (width, h)
    elif height:
        target = (int(w * height / h), height) if keep_aspect else (w, height)
    else:
        raise SystemExit("resize 需要 --width 和/或 --height")
    resample = Image.Resampling.LANCZOS if not keep_aspect else Image.Resampling.LANCZOS
    img.resize(target, resample=resample).save(dst)


def pixelate_image(
    src: Path,
    dst: Path,
    *,
    block: int,
    palette: int,
    scale_up: bool,
) -> None:
    img = cv2.imread(str(src), cv2.IMREAD_UNCHANGED)
    if img is None:
        raise RuntimeError(f"無法讀取：{src}")
    h, w = img.shape[:2]
    small_w = max(1, w // block)
    small_h = max(1, h // block)
    small = cv2.resize(img, (small_w, small_h), interpolation=cv2.INTER_AREA)
    if palette > 0 and small.ndim >= 3 and small.shape[2] >= 3:
        flat = small.reshape(-1, 3).astype(np.float32)
        criteria = (cv2.TERM_CRITERIA_EPS + cv2.TERM_CRITERIA_MAX_ITER, 20, 1.0)
        _compactness, labels, centers = cv2.kmeans(
            flat,
            palette,
            None,
            criteria,
            3,
            cv2.KMEANS_PP_CENTERS,
        )
        centers = np.uint8(centers)
        quantized = centers[labels.flatten()].reshape(small.shape)
        small = quantized
    if scale_up:
        out = cv2.resize(small, (w, h), interpolation=cv2.INTER_NEAREST)
    else:
        out = small
    cv2.imwrite(str(dst), out)


def cmd_remove_bg(args: argparse.Namespace) -> None:
    out_dir = Path(args.output) if args.output else None
    if out_dir:
        out_dir.mkdir(parents=True, exist_ok=True)
    for src in iter_images(args.input, args.recursive):
        dst = output_path(src, out_dir, args.suffix)
        remove_white_background(src, dst, threshold=args.threshold, fuzz=args.fuzz)
        print(dst)


def cmd_resize(args: argparse.Namespace) -> None:
    out_dir = Path(args.output) if args.output else None
    if out_dir:
        out_dir.mkdir(parents=True, exist_ok=True)
    for src in iter_images(args.input, args.recursive):
        dst = output_path(src, out_dir, args.suffix)
        resize_image(src, dst, width=args.width, height=args.height, keep_aspect=not args.stretch)
        print(dst)


def cmd_pixelate(args: argparse.Namespace) -> None:
    out_dir = Path(args.output) if args.output else None
    if out_dir:
        out_dir.mkdir(parents=True, exist_ok=True)
    for src in iter_images(args.input, args.recursive):
        dst = output_path(src, out_dir, args.suffix)
        pixelate_image(
            src,
            dst,
            block=args.block,
            palette=args.palette,
            scale_up=not args.small_only,
        )
        print(dst)


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description="批量圖片處理：去白底 / 縮放 / 像素化")
    sub = parser.add_subparsers(dest="command", required=True)

    common = argparse.ArgumentParser(add_help=False)
    common.add_argument("input", nargs="+", help="檔案或資料夾")
    common.add_argument("-o", "--output", help="輸出資料夾（預設寫回原目錄）")
    common.add_argument("-r", "--recursive", action="store_true", help="遞迴子資料夾")
    common.add_argument("--suffix", default="_out", help="輸出檔名後綴，預設 _out")

    p_bg = sub.add_parser("remove-bg", parents=[common], help="去除白底 → 透明 PNG")
    p_bg.add_argument("--threshold", type=int, default=240, help="RGB 最低值，預設 240")
    p_bg.add_argument("--fuzz", type=int, default=24, help="與純白的距離容差 0-255，預設 24")
    p_bg.set_defaults(func=cmd_remove_bg)

    p_rs = sub.add_parser("resize", parents=[common], help="批量調整尺寸")
    p_rs.add_argument("-W", "--width", type=int, help="目標寬度")
    p_rs.add_argument("-H", "--height", type=int, help="目標高度")
    p_rs.add_argument("--stretch", action="store_true", help="不保持比例，強制拉伸")
    p_rs.set_defaults(func=cmd_resize)

    p_px = sub.add_parser("pixelate", parents=[common], help="像素復古化")
    p_px.add_argument("-b", "--block", type=int, default=8, help="每 N 像素合為 1 格，預設 8")
    p_px.add_argument("-p", "--palette", type=int, default=16, help="調色盤色數，0=關閉，預設 16")
    p_px.add_argument("--small-only", action="store_true", help="只輸出縮小版，不放大回原尺寸")
    p_px.set_defaults(func=cmd_pixelate)

    return parser


def main(argv: list[str] | None = None) -> int:
    parser = build_parser()
    args = parser.parse_args(argv)
    args.func(args)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
