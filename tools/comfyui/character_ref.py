#!/usr/bin/env python3
"""Pick and prepare character reference images for ComfyUI img2img."""
from __future__ import annotations

import re
import shutil
from pathlib import Path

REF_ROOT = Path("/Volumes/磁盘1/star3/图片_ref_star3/01_characters")
COMFY_INPUT = Path("/Users/luke/ComfyUI/input")
COMFY_OUTPUT = Path("/Users/luke/ComfyUI/output")
PROJECT_ROOT = Path("/Users/luke/project-star-3")
PROJECT_ARTIST_SOURCES = {
    "artist_001": PROJECT_ROOT / "cursor_png" / "artist_001.png",
    "artist_002": PROJECT_ROOT / "cursor_png" / "artist_002.png",
    "artist_003": PROJECT_ROOT / "cursor_png" / "artist_003.png",
}

CHARACTER_ROOTS = (
    REF_ROOT / "playable_pc",
    REF_ROOT / "story_protagonist" / "ken",
    REF_ROOT / "story_protagonist" / "odo",
)

# Flat story folders (png files directly inside, not ref_* subfolders).
FLAT_CHARACTER_ALIASES = {
    "ken": REF_ROOT / "story_protagonist" / "ken",
    "odo": REF_ROOT / "story_protagonist" / "odo",
    "story_ken": REF_ROOT / "story_protagonist" / "ken",
    "story_odo": REF_ROOT / "story_protagonist" / "odo",
}

# Prefer standing portrait sheets over huge battle atlases.
PREFERRED_SUFFIXES = (
    "_bidl.png",
    "_trimunq.png",
    "_batk_swing.png",
    "_spr_add0.png",
    "_spr.png",
    "_trimbtl.png",
)

SKIP_PARTS = ("_add1", "_adds", "_no.png", "_mask", "_trimbtl_add", "_trimunq_add")


def list_character_dirs() -> list[Path]:
    found: dict[str, Path] = {}
    for root in CHARACTER_ROOTS:
        if not root.is_dir():
            continue
        pngs = list(root.glob("*.png"))
        if pngs:
            found[root.name] = root
            continue
        for path in sorted(root.iterdir()):
            if path.is_dir() and not path.name.startswith("_"):
                found[path.name] = path
    return [found[k] for k in sorted(found)]


def resolve_character_dir(arg: str) -> Path:
    candidate = Path(arg)
    if candidate.is_dir():
        return candidate

    key = candidate.name.lower()
    if key in FLAT_CHARACTER_ALIASES:
        return FLAT_CHARACTER_ALIASES[key]

    name = candidate.name
    if not name.startswith("ref_"):
        name = f"ref_{name}"

    for root in CHARACTER_ROOTS:
        path = root / name
        if path.is_dir():
            return path

    matches = [p for p in list_character_dirs() if name in p.name or p.name == key]
    if len(matches) == 1:
        return matches[0]
    if len(matches) > 1:
        raise SystemExit(f"ambiguous id {arg!r}: {[p.name for p in matches]}")

    raise SystemExit(f"character folder not found: {arg}")


def score_texture(path: Path) -> tuple[int, int, str]:
    name = path.name.lower()
    if any(part in name for part in SKIP_PARTS):
        return (999, 0, name)

    rank = 50
    for idx, suffix in enumerate(PREFERRED_SUFFIXES):
        if name.endswith(suffix):
            rank = idx
            break

    try:
        from PIL import Image

        with Image.open(path) as img:
            w, h = img.size
            pixels = w * h
    except Exception:
        pixels = 0
        w, h = 0, 0

    # Prefer square/large atlases; penalize tiny icons.
    if pixels < 128 * 128:
        rank += 20
    if w > 0 and h > 0 and max(w, h) / max(min(w, h), 1) > 3.5:
        rank += 5

    return (rank, -pixels, name)


def pick_reference_texture(char_dir: Path) -> Path:
    pngs = list(char_dir.glob("*.png"))
    if not pngs:
        raise SystemExit(f"no png in {char_dir}")

    ranked = sorted((score_texture(p), p) for p in pngs)
    return ranked[0][1]


def extract_sprite_crop(img) -> object:
    """Crop one standing frame from common Octopath-style sheets."""
    from PIL import Image

    w, h = img.size
    name_hint = getattr(img, "filename", "") or ""

    if "bidl" in name_hint.lower() and w <= 320 and h <= 640:
        cols, rows = 2, 3
        cw, ch = w // cols, h // rows
        return img.crop((0, 0, cw, ch))

    if "trimunq" in name_hint.lower() and w == h and w >= 512:
        # Often a single large portrait in upper area.
        side = w // 2
        return img.crop((w // 4, 0, w // 4 + side, side))

    return img


def prepare_reference_image(char_dir: Path, dest_name: str | None = None) -> tuple[Path, Path]:
    from PIL import Image

    source = pick_reference_texture(char_dir)
    char_id = char_dir.name if char_dir.name not in {"ken", "odo"} else f"story_{char_dir.name}"
    dest_name = dest_name or f"star3_{char_id}_ref.png"
    COMFY_INPUT.mkdir(parents=True, exist_ok=True)
    dest = COMFY_INPUT / dest_name

    with Image.open(source) as img:
        img = img.convert("RGBA")
        img.filename = source.name  # type: ignore[attr-defined]
        img = extract_sprite_crop(img)
        canvas = Image.new("RGBA", (512, 768), (255, 255, 255, 255))
        target_h = 640
        scale = min(480 / img.width, target_h / img.height)
        if scale > 1.0:
            new_size = (max(1, int(img.width * scale)), max(1, int(img.height * scale)))
            img = img.resize(new_size, Image.Resampling.NEAREST)
        else:
            img.thumbnail((480, target_h), Image.Resampling.LANCZOS)
        x = (512 - img.width) // 2
        y = (768 - img.height) // 2
        canvas.paste(img, (x, y), img)
        canvas.save(dest, format="PNG")

    meta = COMFY_INPUT / f"{dest.stem}.source.txt"
    meta.write_text(f"char_dir={char_dir}\nsource={source}\n", encoding="utf-8")
    return source, dest


def _fit_on_canvas(img, canvas_w: int, canvas_h: int, margin: int = 4):
    from PIL import Image

    canvas = Image.new("RGBA", (canvas_w, canvas_h), (255, 255, 255, 255))
    fit_w = max(1, canvas_w - margin * 2)
    fit_h = max(1, canvas_h - margin * 2)
    resample = Image.Resampling.NEAREST if max(canvas_w, canvas_h) <= 128 else Image.Resampling.LANCZOS
    fitted = img.copy()
    fitted.thumbnail((fit_w, fit_h), resample)
    x = (canvas_w - fitted.width) // 2
    y = (canvas_h - fitted.height) // 2
    canvas.paste(fitted, (x, y), fitted)
    return canvas


def prepare_project_artist(
    artist_id: str,
    dest_name: str | None = None,
    canvas_w: int = 512,
    canvas_h: int = 768,
    margin: int = 4,
) -> tuple[Path, Path]:
    """Use project cursor_png/{id}.png as img2img reference."""
    from PIL import Image

    source = PROJECT_ARTIST_SOURCES.get(artist_id)
    if source is None or not source.is_file():
        raise SystemExit(f"project source missing: {source}")

    dest_name = dest_name or f"star3_{artist_id}_ref.png"
    COMFY_INPUT.mkdir(parents=True, exist_ok=True)
    dest = COMFY_INPUT / dest_name

    with Image.open(source) as img:
        canvas = _fit_on_canvas(img.convert("RGBA"), canvas_w, canvas_h, margin=margin)
        canvas.save(dest, format="PNG")

    meta = COMFY_INPUT / f"{dest.stem}.source.txt"
    meta.write_text(
        f"artist_id={artist_id}\nsource={source}\ncanvas={canvas_w}x{canvas_h}\n",
        encoding="utf-8",
    )
    return source, dest


def finalize_pixel_sprite(
    src: Path,
    dest: Path,
    size: int = 128,
    colors: int = 36,
    zoom: float = 1.18,
    face_bias: float = 0.12,
    palette_source: Path | None = None,
    saturate: float = 1.0,
) -> Path:
    """Force exact NxN canvas, nearest-neighbor + palette quantize for clean pixels."""
    from PIL import Image, ImageEnhance

    with Image.open(src) as img:
        img = img.convert("RGBA")
        if zoom > 1.0:
            w, h = img.size
            cw, ch = int(w / zoom), int(h / zoom)
            left = max(0, (w - cw) // 2)
            top = max(0, int((h - ch) * face_bias))
            top = min(top, max(0, h - ch))
            img = img.crop((left, top, left + cw, top + ch))
        canvas = _fit_on_canvas(img, size, size, margin=1)
        rgb = canvas.convert("RGB")
        if saturate != 1.0:
            rgb = ImageEnhance.Color(rgb).enhance(saturate)
            rgb = ImageEnhance.Contrast(rgb).enhance(1.04)

        if palette_source and palette_source.is_file():
            with Image.open(palette_source) as pal_src:
                ref = pal_src.convert("RGB").quantize(
                    colors=colors,
                    method=Image.Quantize.MEDIANCUT,
                    dither=Image.Dither.NONE,
                )
            quantized = rgb.quantize(palette=ref, dither=Image.Dither.NONE).convert("RGBA")
        else:
            quantized = rgb.quantize(
                colors=colors,
                method=Image.Quantize.MEDIANCUT,
                dither=Image.Dither.NONE,
            ).convert("RGBA")
        dest.parent.mkdir(parents=True, exist_ok=True)
        quantized.save(dest, format="PNG")
    return dest


def project_artist_prompt(artist_id: str, canvas: int = 512, vivid: bool = False) -> str:
    if vivid:
        sprite_bits = (
            "128x128 game sprite, crisp pixels, no anti-aliasing, "
            if canvas <= 128
            else ""
        )
        prompts = {
            "artist_001": (
                f"{sprite_bits}"
                "anime character illustration, vivid saturated colors, bright clean color blocks, "
                "1girl, Yoko, age 18, short brown hair with ahoge, "
                "very large detailed amber orange eyes, white eye highlights, dark pupils, sharp eyelashes, "
                "black sailor school uniform, bright red neckerchief, "
                "golden yellow electric guitar, full body standing portrait, pure white background, "
                "same colors as reference, not vintage, not retro, not muted"
            ),
        }
        return prompts.get(
            artist_id,
            f"anime character, vivid saturated colors, bright color blocks, white background, {artist_id}",
        )

    sprite_bits = (
        "128x128 pixel sprite, crisp square pixels, no anti-aliasing, no blur, "
        if canvas <= 128
        else ""
    )
    prompts = {
        "artist_001": (
            f"Pixel Art, PIXARFK, {sprite_bits}"
            "octopath traveler HD-2D style, 1girl, Yoko, age 18, "
            "short brown hair with ahoge, "
            "large detailed amber eyes, bright eye highlights, clear pupils, expressive eyes, "
            "black sailor school uniform, red neckerchief, "
            "holding yellow vintage electric guitar, indie rock musician, full body standing portrait, "
            "simple white background, limited color palette, sharp pixels"
        ),
        "artist_002": (
            "Pixel Art, PIXARFK, octopath traveler HD-2D style, 1woman, tall, shy, "
            "full body standing portrait, simple white background, sharp pixels"
        ),
        "artist_003": (
            "Pixel Art, PIXARFK, octopath traveler HD-2D style, 1woman, athletic, "
            "full body standing portrait, simple white background, sharp pixels"
        ),
    }
    return prompts.get(
        artist_id,
        f"Pixel Art, PIXARFK, octopath traveler HD-2D style, game character, "
        f"full body standing portrait, white background, {artist_id}",
    )


def default_prompt(char_id: str) -> str:
    return (
        f"Pixel Art, PIXARFK, octopath traveler HD-2D style, single game character, "
        f"full body standing portrait, clean silhouette, limited color palette, "
        f"sharp pixels, simple white background, character reference {char_id}"
    )


DEFAULT_NEGATIVE = (
    "blurry, photo, realistic, 3d render, text, watermark, sprite sheet grid, "
    "multiple characters, deformed, smooth gradient, anti-aliased"
)
