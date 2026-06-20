# ComfyUI 生图工具（project-star-3）

> 主 spec 仍见桌面 [`图片规格与尺寸.md`](file:///Users/luke/Desktop/docs/图片规格与尺寸.md)。  
> ComfyUI 本体在 **`/Users/luke/ComfyUI`**，模型与输出 **不进** repo。

## 快速开始

```bash
# 1) 下载 POC 模型（约 2.2 GB，只需一次）
bash tools/comfyui/download_models.sh

# 2) 安装 workflow 到 ComfyUI UI
bash tools/comfyui/install_workflows.sh

# 3) 启动服务
bash tools/comfyui/start_comfyui.sh
# 浏览器打开 http://127.0.0.1:8188
```

## POC 模型集（Mac M4 · 16GB）

| 文件 | 路径 | 大小 |
|------|------|------|
| `DreamShaper_8_pruned.safetensors` | `ComfyUI/models/checkpoints/` | ~2.1 GB |
| `PixelArtRedmond15V-PixelArt-PIXARFK.safetensors` | `ComfyUI/models/loras/` | ~27 MB |

触发词：`Pixel Art`, `PIXARFK`（LoRA 说明见 HuggingFace `artificialguybr/pixelartredmond-1-5v-pixel-art-loras-for-sd-1-5`）。

## Workflow

- UI 版：`tools/comfyui/workflows/pixel_portrait_poc.json`
- 512×768 竖图 POC；输出前缀 `project_star3_pixel_poc`
- 输出目录：`/Users/luke/ComfyUI/output/`

## 命令行 smoke test

ComfyUI 已启动时：

```bash
python3 tools/comfyui/run_poc.py
```

## 与 Godot 资产链的关系

```text
ComfyUI 像素 POC（512×768 或更大）
  -> Windows / Aseprite 手工清理、降色、修边（占位流程）
  -> 白底或透明 PNG 进 cursor_png/{id}.png
  -> tools/image_tools/process_character_exports.py
  -> assets/characters/.../avatar|portrait/
```

**注意**：像素 sprite 规格尚未写入桌面总 spec；导入 Godot 前须先更新 [`项目梳理_明星志愿3精神续作.md`](file:///Users/luke/Desktop/docs/项目梳理_明星志愿3精神续作.md)。

## 单角色参考喂图（img2img）

从 `图片_ref_star3/01_characters/` 选一个角色文件夹，自动挑最佳贴图 → 512×768 白底 → ComfyUI img2img。

```bash
# 列出可选角色（playable_pc + 主角 ken/odo）
python3 tools/comfyui/list_characters.py

# 只准备参考图到 ComfyUI/input/（不跑 SD）
python3 tools/comfyui/feed_character.py ref_1002_kenj002_mle --prepare-only

# 准备 + img2img（denoise 越低越像参考，默认 0.38）
python3 tools/comfyui/feed_character.py ref_1002_kenj002_mle
python3 tools/comfyui/feed_character.py ref_1002_kenj002_mle --denoise 0.30

# UI workflow
bash tools/comfyui/install_workflows.sh   # 含 pixel_img2img_character.json
```

输出：`ComfyUI/output/star3_ref_XXXX_*.png`  
输入参考：`ComfyUI/input/star3_ref_XXXX_ref.png`

## 相关文档

- 交接总览：`COMFYUI_HANDOFF.md`
- 参考图整理：`/Volumes/磁盘1/star3/图片_ref_star3/`
