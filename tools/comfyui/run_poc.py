#!/usr/bin/env python3
"""Queue one pixel-art POC generation via ComfyUI HTTP API."""
from __future__ import annotations

import json
import sys
import time
import urllib.error
import urllib.request
import uuid

HOST = "127.0.0.1:8188"

PROMPT = {
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
            "strength_model": 0.85,
            "strength_clip": 0.85,
        },
    },
    "6": {
        "class_type": "CLIPTextEncode",
        "inputs": {
            "clip": ["10", 1],
            "text": (
                "Pixel Art, PIXARFK, 1girl, young indie rock musician, electric guitar, "
                "retro 16-bit game character, full body standing portrait, simple white background"
            ),
        },
    },
    "7": {
        "class_type": "CLIPTextEncode",
        "inputs": {
            "clip": ["10", 1],
            "text": "blurry, photo, realistic, 3d render, text, watermark, deformed, smooth gradient",
        },
    },
    "5": {
        "class_type": "EmptyLatentImage",
        "inputs": {"width": 512, "height": 768, "batch_size": 1},
    },
    "3": {
        "class_type": "KSampler",
        "inputs": {
            "seed": 8675309,
            "steps": 28,
            "cfg": 7.0,
            "sampler_name": "euler",
            "scheduler": "normal",
            "denoise": 1.0,
            "model": ["10", 0],
            "positive": ["6", 0],
            "negative": ["7", 0],
            "latent_image": ["5", 0],
        },
    },
    "8": {
        "class_type": "VAEDecode",
        "inputs": {"samples": ["3", 0], "vae": ["4", 2]},
    },
    "9": {
        "class_type": "SaveImage",
        "inputs": {"filename_prefix": "project_star3_pixel_poc", "images": ["8", 0]},
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
    with urllib.request.urlopen(req, timeout=30) as resp:
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
    try:
        with urllib.request.urlopen(f"http://{HOST}/", timeout=5):
            pass
    except urllib.error.URLError as exc:
        print(f"ComfyUI not reachable at http://{HOST}/ ({exc})", file=sys.stderr)
        print("Start it with: tools/comfyui/start_comfyui.sh", file=sys.stderr)
        return 1

    client_id = str(uuid.uuid4())
    queued = post_json("/prompt", {"prompt": PROMPT, "client_id": client_id})
    prompt_id = queued["prompt_id"]
    print(f"queued prompt_id={prompt_id}")

    result = wait_for_history(prompt_id)
    outputs = result.get("outputs", {})
    for node_id, node_out in outputs.items():
        for image in node_out.get("images", []):
            print(
                "saved:",
                f"{image.get('filename')} (subfolder={image.get('subfolder')}, type={image.get('type')})",
            )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
