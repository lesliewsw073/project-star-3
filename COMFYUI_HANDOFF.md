# ComfyUI Handoff

> Last updated: 2026-06-20
> Owner note: this file records the Mac-side ComfyUI setup so Cursor can continue the SD pixel-art workflow without rereading the chat.

## Purpose

Set up a lightweight ComfyUI environment on the Mac for future batch SD production of pixel-art assets.

The intended asset pipeline is:

```text
large original artwork / character reference
  -> ComfyUI generation workflow on Mac M4
  -> pixel-art style outputs
  -> manual cleanup/optimization on Windows, likely Aseprite
  -> final selected assets imported into project-star-3
```

No game project code was changed for this setup.

## Installed

### uv

Installed via:

```bash
curl -LsSf https://astral.sh/uv/install.sh | sh
```

Location:

```text
/Users/luke/.local/bin/uv
/Users/luke/.local/bin/uvx
```

Verified:

```text
uv 0.11.23
```

Note: the shell may need PATH refresh for normal `uv` usage:

```bash
source "$HOME/.local/bin/env"
```

The setup commands used the full path directly.

### ComfyUI

Repository location:

```text
/Users/luke/ComfyUI
```

Cloned from:

```text
https://github.com/comfyanonymous/ComfyUI.git
```

### Python virtual environment

Created with:

```bash
cd /Users/luke/ComfyUI
/Users/luke/.local/bin/uv venv --python 3.12
```

Environment:

```text
/Users/luke/ComfyUI/.venv
Python 3.12.13
```

### ComfyUI dependencies

Installed with:

```bash
cd /Users/luke/ComfyUI
/Users/luke/.local/bin/uv pip install -r requirements.txt
```

Important verified versions:

```text
ComfyUI 0.25.0
Python 3.12.13
PyTorch 2.12.1
```

### ComfyUI-Manager

Manager dependency was required by the current ComfyUI build.

Installed with:

```bash
cd /Users/luke/ComfyUI
/Users/luke/.local/bin/uv pip install -r manager_requirements.txt
```

Verified package:

```text
comfyui-manager 4.2.2
```

## Hardware / System

Verified environment after macOS update:

```text
macOS 26.5.1
arm64
Apple M4 GPU, Metal supported
RAM/VRAM shared: 16 GB
Free disk space at setup time: about 144 GiB
```

PyTorch MPS diagnostic:

```text
torch.backends.mps.is_built() = True
torch.backends.mps.is_available() = True
```

Important note: sandboxed terminal checks may report `mps_available=False`, but the user environment reports `True`. ComfyUI startup confirmed:

```text
Device: mps
```

## Start Command

Use this to start ComfyUI:

```bash
cd /Users/luke/ComfyUI
/Users/luke/ComfyUI/.venv/bin/python main.py --listen 127.0.0.1 --port 8188 --disable-auto-launch --enable-manager
```

Open:

```text
http://127.0.0.1:8188
```

Verified with local HTTP check:

```text
HTTP/1.1 200 OK
```

## Model Directories

ComfyUI created the standard model folders under:

```text
/Users/luke/ComfyUI/models
```

Important folders for the next phase:

```text
/Users/luke/ComfyUI/models/checkpoints
/Users/luke/ComfyUI/models/loras
/Users/luke/ComfyUI/models/controlnet
/Users/luke/ComfyUI/models/clip_vision
/Users/luke/ComfyUI/models/vae
/Users/luke/ComfyUI/models/upscale_models
```

## Project-side Tooling (2026-06-20 · Cursor)

Added under `project-star-3/tools/comfyui/`:

| File | Purpose |
|------|---------|
| `download_models.sh` | SD1.5 POC models (~2.2 GB total) |
| `start_comfyui.sh` | Start server on `127.0.0.1:8188` |
| `install_workflows.sh` | Copy workflows → `ComfyUI/user/default/workflows/` |
| `workflows/pixel_portrait_poc.json` | DreamShaper + PixelArtRedmond LoRA UI workflow |
| `run_poc.py` | HTTP API smoke test (queue one image) |
| `README.md` | Quick start + Godot pipeline reminder |

## POC Model Set (Mac M4 · 16GB)

| Asset | Path | Size |
|-------|------|------|
| `DreamShaper_8_pruned.safetensors` | `ComfyUI/models/checkpoints/` | ~2.1 GB |
| `PixelArtRedmond15V-PixelArt-PIXARFK.safetensors` | `ComfyUI/models/loras/` | ~27 MB |

Trigger words: `Pixel Art`, `PIXARFK`.

Download:

```bash
bash /Users/luke/project-star-3/tools/comfyui/download_models.sh
```

## Pixel POC Workflow

- UI workflow: `tools/comfyui/workflows/pixel_portrait_poc.json`
- Default canvas: **512×768** (portrait-ish POC, not final Godot sizes)
- Output prefix: `project_star3_pixel_poc` → `/Users/luke/ComfyUI/output/`
- Smoke test: `python3 tools/comfyui/run_poc.py` (ComfyUI must be running)

## Verified (2026-06-20 · Cursor)

- [x] POC models downloaded (DreamShaper 8 + PixelArtRedmond LoRA)
- [x] Workflow installed to `ComfyUI/user/default/workflows/pixel_portrait_poc.json`
- [x] ComfyUI starts on `http://127.0.0.1:8188` (MPS)
- [x] API smoke test produced `ComfyUI/output/project_star3_pixel_poc_00001_.png`

## Not Done Yet

- [ ] First POC image reviewed by 勇者大人
- [ ] Pixel sprite frame spec written into desktop master spec (before Godot import)
- [ ] img2img / reference workflow for existing `cursor_png/` characters
- [ ] Windows Aseprite cleanup SOP documented
- [ ] No outputs imported into Godot `assets/characters/` yet

## Recommended Next Steps

1. Finish model download → start ComfyUI → open `http://127.0.0.1:8188`.
2. Load workflow **pixel_portrait_poc** → Queue Prompt → review output in `ComfyUI/output/`.
3. Decide sprite target before batch work (see draft below).
4. Only copy selected finals through `cursor_png/` → `process_character_exports.py` → `assets/characters/`.
5. Update desktop master spec **before** importing any pixel sprite into Godot.

### Draft sprite targets (needs 勇者大人 sign-off)

| Use | Draft spec | Notes |
|-----|------------|-------|
| Standing sprite POC | 64×64 or 96×96, transparent | ComfyUI generates larger; downscale in Aseprite |
| HD-2D portrait source | 512×768 SD output | Feeds existing avatar/portrait batch script after cleanup |
| UI pixel icons | 32×32 / 48×48 | News panel / facility icons — separate from character三夹 |

## Project Integration Reminder

For this project, visual assets should follow the master spec:

```text
/Users/luke/Desktop/docs/图片规格与尺寸.md
```

Current game image rules from that spec:

```text
avatar:   512x512 RGBA PNG
portrait: 900x1400 RGBA PNG
cg:       1600x900 PNG/JPG
```

Pixel sprites are not finalized in the existing image spec yet. Before importing sprite assets into Godot, update the master project spec first.
