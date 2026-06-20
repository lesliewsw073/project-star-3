#!/Users/luke/project-star-3/tools/image_tools/.venv/bin/python
"""Prepare a character folder reference and run ComfyUI img2img."""
from __future__ import annotations

import argparse
import json
import sys
import time
import urllib.error
import urllib.request
import uuid
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from character_ref import (  # noqa: E402
    COMFY_OUTPUT,
    DEFAULT_NEGATIVE,
    PROJECT_ARTIST_SOURCES,
    PROJECT_ROOT,
    default_prompt,
    finalize_pixel_sprite,
    prepare_project_artist,
    prepare_reference_image,
    project_artist_prompt,
    resolve_character_dir,
)

VIVID_NEGATIVE = (
    DEFAULT_NEGATIVE
    + ", desaturated, muted colors, dull, sepia, vintage filter, retro style, "
    "octopath style, faded, low contrast, blank eyes, dot eyes, missing eyes, faceless"
)

SPRITE_NEGATIVE = (
    DEFAULT_NEGATIVE
    + ", high resolution, detailed texture, soft shading, gradient, semi-realistic, "
    "blank eyes, dot eyes, missing eyes, closed eyes, faceless"
)

HOST = "127.0.0.1:8188"


def build_prompt(
    input_filename: str,
    char_id: str,
    positive: str,
    negative: str,
    denoise: float,
    seed: int,
    lora_strength: float = 0.85,
) -> dict:
    prefix = f"star3_{char_id}"
    return {
        "4": {
            "class_type": "CheckpointLoaderSimple",
            "inputs": {"ckpt_name": "DreamShaper_8_pruned.safetensors"},
        },
        "10": {
            "class_type": "LoraLoader",
            "inputs": {
                "model": ["4", 0],
                "clip": ["4", 1],
                "lora_name": "PixelArtRedmond15V-PixelArt-PIXARFK.safetensors",
                "strength_model": lora_strength,
                "strength_clip": lora_strength,
            },
        },
        "11": {
            "class_type": "LoadImage",
            "inputs": {"image": input_filename},
        },
        "12": {
            "class_type": "VAEEncode",
            "inputs": {"pixels": ["11", 0], "vae": ["4", 2]},
        },
        "6": {
            "class_type": "CLIPTextEncode",
            "inputs": {"clip": ["10", 1], "text": positive},
        },
        "7": {
            "class_type": "CLIPTextEncode",
            "inputs": {"clip": ["10", 1], "text": negative},
        },
        "3": {
            "class_type": "KSampler",
            "inputs": {
                "seed": seed,
                "steps": 28,
                "cfg": 7.0,
                "sampler_name": "euler",
                "scheduler": "normal",
                "denoise": denoise,
                "model": ["10", 0],
                "positive": ["6", 0],
                "negative": ["7", 0],
                "latent_image": ["12", 0],
            },
        },
        "8": {
            "class_type": "VAEDecode",
            "inputs": {"samples": ["3", 0], "vae": ["4", 2]},
        },
        "9": {
            "class_type": "SaveImage",
            "inputs": {"filename_prefix": prefix, "images": ["8", 0]},
        },
    }


def post_json(path: str, payload: dict) -> dict:
    data = json.dumps(payload).encode("utf-8")
    req = urllib.request.Request(
        f"http://{HOST}{path}",
        data=data,
        headers={"Content-Type": "application/json"},
        method="POST",
    )
    with urllib.request.urlopen(req, timeout=60) as resp:
        return json.loads(resp.read().decode("utf-8"))


def wait_for_history(prompt_id: str, timeout_s: int = 600) -> dict:
    deadline = time.time() + timeout_s
    while time.time() < deadline:
        with urllib.request.urlopen(f"http://{HOST}/history/{prompt_id}", timeout=30) as resp:
            history = json.loads(resp.read().decode("utf-8"))
        if prompt_id in history:
            return history[prompt_id]
        time.sleep(2)
    raise TimeoutError(f"prompt {prompt_id} did not finish within {timeout_s}s")


def main() -> int:
    parser = argparse.ArgumentParser(description="Feed one character folder to ComfyUI img2img")
    parser.add_argument("character", nargs="?", help="folder name e.g. ref_1002_kenj002_mle")
    parser.add_argument("--artist", default="", help="project artist id e.g. artist_001")
    parser.add_argument("--prepare-only", action="store_true", help="only copy reference to ComfyUI/input")
    parser.add_argument("--denoise", type=float, default=0.38, help="img2img strength (lower=closer to ref)")
    parser.add_argument("--canvas", type=int, default=512, help="square canvas edge (512 or 128)")
    parser.add_argument("--seed", type=int, default=8675309)
    parser.add_argument("--prompt", default="", help="override positive prompt")
    parser.add_argument("--negative", default="")
    parser.add_argument("--vivid", action="store_true", help="match source colors, no retro pixel look")
    parser.add_argument("--lora", type=float, default=-1.0, help="LoRA strength override")
    parser.add_argument(
        "--out",
        default="",
        help="optional final PNG path after pixel finalize (128 canvas)",
    )
    args = parser.parse_args()

    canvas = args.canvas
    if canvas not in {128, 512}:
        parser.error("--canvas must be 128 or 512")
    canvas_h = 768 if canvas == 512 else canvas
    vivid = args.vivid or bool(args.artist and canvas == 128)
    if args.lora >= 0:
        lora_strength = args.lora
    elif vivid:
        lora_strength = 0.58
    elif canvas == 128:
        lora_strength = 0.92
    else:
        lora_strength = 0.85
    if args.negative:
        negative = args.negative
    elif vivid:
        negative = VIVID_NEGATIVE
    elif canvas == 128:
        negative = SPRITE_NEGATIVE
    else:
        negative = DEFAULT_NEGATIVE

    project_source: Path | None = None

    if args.artist:
        artist_id = args.artist if args.artist.startswith("artist_") else f"artist_{args.artist}"
        char_id = artist_id
        gen_w = 512 if canvas == 128 else canvas
        gen_h = 768 if canvas == 512 else (768 if canvas == 128 else canvas)
        project_source = PROJECT_ARTIST_SOURCES.get(artist_id)
        source, prepared = prepare_project_artist(
            artist_id,
            canvas_w=gen_w,
            canvas_h=gen_h,
            margin=1 if canvas == 128 else 4,
        )
        print(f"artist:    {artist_id}")
        if canvas == 128:
            print(f"gen_size:  {gen_w}x{gen_h} -> finalize 128x128 vivid={vivid}")
    elif args.character:
        char_dir = resolve_character_dir(args.character)
        char_id = char_dir.name if char_dir.name not in {"ken", "odo"} else f"story_{char_dir.name}"
        source, prepared = prepare_reference_image(char_dir)
        print(f"char_dir:  {char_dir}")
    else:
        parser.error("provide character folder or --artist artist_001")

    print(f"texture:   {source.name}")
    print(f"prepared:  {prepared}")

    if args.prepare_only:
        print("(prepare-only, skipped ComfyUI queue)")
        return 0

    try:
        with urllib.request.urlopen(f"http://{HOST}/", timeout=5):
            pass
    except urllib.error.URLError as exc:
        print(f"ComfyUI not reachable: {exc}", file=sys.stderr)
        print("Start: bash tools/comfyui/start_comfyui.sh", file=sys.stderr)
        return 1

    if args.denoise == 0.38 and vivid:
        denoise = 0.34
    else:
        denoise = args.denoise

    positive = args.prompt or (
        project_artist_prompt(char_id, canvas=canvas, vivid=vivid)
        if args.artist
        else default_prompt(char_id)
    )
    prompt = build_prompt(
        prepared.name,
        char_id,
        positive,
        negative,
        denoise,
        args.seed,
        lora_strength=lora_strength,
    )

    client_id = str(uuid.uuid4())
    queued = post_json("/prompt", {"prompt": prompt, "client_id": client_id})
    prompt_id = queued["prompt_id"]
    print(f"queued:    prompt_id={prompt_id} denoise={denoise} lora={lora_strength}")

    result = wait_for_history(prompt_id)
    raw_output: Path | None = None
    for node_out in result.get("outputs", {}).values():
        for image in node_out.get("images", []):
            fname = image.get("filename")
            raw_output = COMFY_OUTPUT / fname
            print(f"raw:       {raw_output}")

    if raw_output and canvas == 128:
        default_out = (
            PROJECT_ROOT / "cursor_png" / "comfyui_output" / f"{char_id}_pixel_128.png"
        )
        final_path = Path(args.out) if args.out else default_out
        finalized = finalize_pixel_sprite(
            raw_output,
            final_path,
            size=128,
            colors=56,
            zoom=1.32 if vivid else 1.18,
            face_bias=0.06 if vivid else 0.12,
            palette_source=project_source if vivid else None,
            saturate=1.08 if vivid else 1.0,
        )
        print(f"final:     {finalized} ({finalized.stat().st_size} bytes)")
    elif raw_output and args.out:
        finalize_pixel_sprite(raw_output, Path(args.out), size=canvas, colors=48)
        print(f"final:     {args.out}")

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
