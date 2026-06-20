#!/usr/bin/env python3
"""Reorganize Octopath-style reference assets into a clean SD-friendly tree.

Source (read-only): /Volumes/磁盘1/star3/图片
Dest (new sibling):  /Volumes/磁盘1/star3/图片_ref_star3
"""
from __future__ import annotations

import csv
import re
import shutil
import unicodedata
from pathlib import Path

SRC_ROOT = Path("/Volumes/磁盘1/star3/图片")
DEST_ROOT = Path("/Volumes/磁盘1/star3/图片_ref_star3")

SKIP_TOP = set()

CHAR_SUBMAP: dict[str, str] = {
    "PC": "01_characters/playable_pc",
    "PC (未分文件夹)": "01_characters/playable_pc/_textures_flat",
    "PlyKen_J000": "01_characters/story_protagonist/ken",
    "PlyOdo_J000": "01_characters/story_protagonist/odo",
    "EVC": "01_characters/event_npc",
    "NPC": "01_characters/town_npc",
    "Animal": "01_characters/animal",
    "UI": "07_ui/character",
    "Weapon": "02_items/weapons",
    "Object": "02_items/character_props",
}

ENV_SUBMAP: dict[str, str] = {
    "BG": "04_environment/background",
    "Field": "04_environment/field",
    "Landscape": "04_environment/landscape",
    "Level": "04_environment/level",
    "Modular": "04_environment/modular",
    "Object": "04_environment/props",
    "Ocean": "04_environment/nature_ocean",
    "Sky": "04_environment/nature_sky",
    "Water": "04_environment/nature_water",
    "建筑": "04_environment/architecture",
}

ENEMY_SUBMAP: dict[str, str] = {
    "KS": "03_enemies/battle/ks",
    "MJ": "03_enemies/battle/mj",
    "敌人icon": "03_enemies/icons",
}

TOP_MAP: dict[str, str] = {
    "Character": "_character",
    "Effect": "05_effects",
    "Enemy": "_enemy",
    "Environment": "_environment",
    "oota": "99_misc/oota",
}


def slug(text: str) -> str:
    text = unicodedata.normalize("NFKC", text.strip())
    text = text.replace(" ", "_").replace("(", "").replace(")", "")
    text = re.sub(r"[^\w\u4e00-\u9fff\-+]", "_", text, flags=re.UNICODE)
    text = re.sub(r"_+", "_", text).strip("_")
    return text.lower() if text.isascii() else text


def ref_segment(name: str) -> str:
    s = slug(name)
    if not s:
        return "ref_unknown"
    if s.startswith("ref_"):
        return s
    return f"ref_{s}"


def map_character(rel_parts: tuple[str, ...]) -> Path:
    if not rel_parts:
        return Path("01_characters/_root")
    head = rel_parts[0]
    if head in CHAR_SUBMAP:
        base = Path(CHAR_SUBMAP[head])
        tail = rel_parts[1:-1] if len(rel_parts) > 1 else ()
    elif head.startswith("NpcCty_"):
        base = Path("01_characters/town_npc/archetype") / ref_segment(head)
        tail = rel_parts[1:-1]
    elif head.startswith("EvcCty_"):
        base = Path("01_characters/event_city/archetype") / ref_segment(head)
        tail = rel_parts[1:-1]
    else:
        base = Path("01_characters/other") / ref_segment(head)
        tail = rel_parts[1:-1]

    extra = Path(*[ref_segment(p) for p in tail]) if tail else Path()
    return base / extra


def map_environment(rel_parts: tuple[str, ...]) -> Path:
    if not rel_parts:
        return Path("04_environment/_root")
    head = rel_parts[0]
    base = Path(ENV_SUBMAP.get(head, f"04_environment/other/{ref_segment(head)}"))
    tail = rel_parts[1:-1]
    extra = Path(*[ref_segment(p) for p in tail]) if tail else Path()
    return base / extra


def map_enemy(rel_parts: tuple[str, ...]) -> Path:
    if not rel_parts:
        return Path("03_enemies/_root")
    head = rel_parts[0]
    base = Path(ENEMY_SUBMAP.get(head, f"03_enemies/other/{ref_segment(head)}"))
    tail = rel_parts[1:-1]
    extra = Path(*[ref_segment(p) for p in tail]) if tail else Path()
    return base / extra


def map_effect(rel_parts: tuple[str, ...]) -> Path:
    base = Path("05_effects")
    tail = rel_parts[:-1]
    extra = Path(*[ref_segment(p) for p in tail]) if tail else Path()
    return base / extra


def map_dest_relative(src: Path) -> Path:
    rel = src.relative_to(SRC_ROOT)
    parts = rel.parts
    top = parts[0]
    rest = parts[1:]

    if top == "Character":
        parent = map_character(rest[:-1])
    elif top == "Environment":
        parent = map_environment(rest[:-1])
    elif top == "Enemy":
        parent = map_enemy(rest[:-1])
    elif top == "Effect":
        parent = map_effect(rest)
    elif top == "oota":
        parent = Path("99_misc/oota")
    else:
        parent = Path("98_unsorted") / ref_segment(top)
        if len(rest) > 1:
            parent = parent.joinpath(*[ref_segment(p) for p in rest[:-1]])

    filename = ref_segment(src.stem) + src.suffix.lower()
    return parent / filename


def write_readme(counts: dict[str, int], total: int) -> None:
    lines = [
        "# 图片_ref_star3",
        "",
        "由 `tools/image_tools/reorganize_octopath_ref.py` 从同级 `图片/` **只读复制** 整理。",
        "原始目录未修改。",
        "",
        "## 目录说明",
        "",
        "| 目录 | 内容 | 文件数 |",
        "|------|------|--------|",
    ]
    for key in sorted(counts):
        lines.append(f"| `{key}` | 见子目录 | {counts[key]} |")
    lines.extend(
        [
            "",
            f"**合计**: {total} 文件",
            "",
            "## 命名规则",
            "",
            "- 顶层不用原 `Character/Effect/...`，改编号英文目录",
            "- 子文件夹加 `ref_` 前缀并 slug 化",
            "- 文件名同样 `ref_` + slug，避免与原路径同名",
            "",
            "## SD 使用建议",
            "",
            "- 角色参考：`01_characters/playable_pc/` 或 `story_protagonist/`",
            "- 道具：`02_items/`",
            "- 场景：`04_environment/`",
            "- 特效：`05_effects/`",
            "- 对照表：`manifest.csv`",
            "",
        ]
    )
    (DEST_ROOT / "README.md").write_text("\n".join(lines), encoding="utf-8")


def main() -> None:
    if not SRC_ROOT.is_dir():
        raise SystemExit(f"source missing: {SRC_ROOT}")

    if DEST_ROOT.exists():
        raise SystemExit(f"dest already exists (delete manually if re-run): {DEST_ROOT}")

    DEST_ROOT.mkdir(parents=True)

    manifest_rows: list[tuple[str, str, int]] = []
    category_counts: dict[str, int] = {}
    used_dest: set[Path] = set()
    copied = 0

    for src in sorted(SRC_ROOT.rglob("*")):
        if not src.is_file():
            continue
        if src.suffix.lower() not in {".png", ".jpg", ".jpeg", ".webp", ".gif", ".psk"}:
            continue

        dest_rel = map_dest_relative(src)
        top_cat = dest_rel.parts[0] if dest_rel.parts else "other"
        category_counts[top_cat] = category_counts.get(top_cat, 0) + 1

        dest = DEST_ROOT / dest_rel
        if dest in used_dest:
            # rare collision after slug
            stem = ref_segment(src.stem + "_" + slug(str(src.relative_to(SRC_ROOT))))
            dest = dest.with_name(stem + dest.suffix.lower())

        used_dest.add(dest)
        dest.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(src, dest)
        manifest_rows.append((str(src), str(dest.relative_to(DEST_ROOT)), src.stat().st_size))
        copied += 1

    manifest_path = DEST_ROOT / "manifest.csv"
    with manifest_path.open("w", newline="", encoding="utf-8") as f:
        writer = csv.writer(f)
        writer.writerow(["source", "dest", "bytes"])
        writer.writerows(manifest_rows)

    write_readme(category_counts, copied)
    print(f"done: {copied} files -> {DEST_ROOT}")
    for k in sorted(category_counts):
        print(f"  {k}: {category_counts[k]}")


if __name__ == "__main__":
    main()
