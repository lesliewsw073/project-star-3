#!/usr/bin/env python3
"""生成 docs/FULL_CODEBASE.md — 專案全部程式碼彙總（供除錯用）。"""

from __future__ import annotations

from datetime import datetime
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
OUT = ROOT / "docs" / "FULL_CODEBASE.md"

SKIP_DIRS = {".git", ".godot", "node_modules", "__pycache__"}
SKIP_NAMES = {".DS_Store", "Thumbs.db"}
INCLUDE_EXT = {".gd", ".py", ".tres", ".tscn", ".godot"}

CATEGORY_ORDER = [
    "專案配置",
    "Autoload 全域單例",
    "Managers",
    "Controllers",
    "UI 腳本",
    "Resources 資源腳本",
    "Components 組件",
    "核心模型",
    "測試腳本",
    "場景與主題",
    "資料 data",
    "工具 tools",
    "其它",
]


def should_skip(path: Path) -> bool:
    if path.name in SKIP_NAMES:
        return True
    if path.suffix == ".uid":
        return True
    if path.suffix not in INCLUDE_EXT:
        return True
    return bool(set(path.parts) & SKIP_DIRS)


def categorize(path: Path) -> str:
    rel = path.as_posix()
    if rel == "project.godot":
        return "專案配置"
    if rel.startswith("scripts/autoload/"):
        return "Autoload 全域單例"
    if rel.startswith("scripts/managers/"):
        return "Managers"
    if rel.startswith("scripts/controllers/"):
        return "Controllers"
    if rel.startswith("scripts/ui/"):
        return "UI 腳本"
    if rel.startswith("scripts/resources/"):
        return "Resources 資源腳本"
    if rel.startswith("scripts/components/"):
        return "Components 組件"
    if rel in (
        "scripts/ArtistInstance.gd",
        "scripts/JobInstance.gd",
        "scripts/CompletionQuality.gd",
    ):
        return "核心模型"
    if rel.startswith("scripts/test/") or rel == "test.gd":
        return "測試腳本"
    if rel.startswith("data/"):
        return "資料 data"
    if rel.startswith("tools/"):
        return "工具 tools"
    if rel.endswith(".tscn") or rel.startswith("UI/"):
        return "場景與主題"
    if rel.startswith("scripts/"):
        return "其它"
    return "其它"


def lang_for(path: Path) -> str:
    ext = path.suffix.lstrip(".")
    return {"gd": "gdscript", "py": "python", "tres": "ini", "tscn": "ini", "godot": "ini"}.get(
        ext, ext
    )


def collect_files() -> list[Path]:
    return sorted(
        (p for p in ROOT.rglob("*") if p.is_file() and not should_skip(p)),
        key=lambda x: str(x).lower(),
    )


def anchor(cat: str) -> str:
    return cat.replace(" ", "-").replace("/", "")


def build() -> None:
    files = collect_files()
    by_cat: dict[str, list[Path]] = {}
    for path in files:
        by_cat.setdefault(categorize(path), []).append(path)

    lines: list[str] = [
        "# Project Star 3 — 完整程式碼彙總",
        "",
        f"> 自動生成：{datetime.now().strftime('%Y-%m-%d %H:%M')}  ",
        f"> 路徑：`{ROOT}`  ",
        f"> 檔案數：**{len(files)}**（`.gd` `.py` `.tres` `.tscn` `project.godot`）  ",
        "> 重新生成：`python3 tools/generate_full_codebase_md.py`  ",
        "",
        "**說明：** 公司規模升級只看金幣、聲望、通告數；**口碑不參與公司規模**。",
        "",
        "## 目錄",
        "",
    ]

    for cat in CATEGORY_ORDER:
        if cat in by_cat:
            lines.append(f"- [{cat}](#{anchor(cat)})（{len(by_cat[cat])}）")

    lines.extend(["", "---", ""])

    for cat in CATEGORY_ORDER:
        if cat not in by_cat:
            continue
        lines.append(f"## {cat}")
        lines.append("")
        for path in by_cat[cat]:
            rel = path.relative_to(ROOT).as_posix()
            try:
                content = path.read_text(encoding="utf-8")
            except OSError as exc:
                content = f"# ERROR: {exc}"
            lines.append(f"### `{rel}`")
            lines.append("")
            lines.append(f"```{lang_for(path)}")
            lines.append(content.rstrip("\n"))
            lines.append("```")
            lines.append("")

    OUT.parent.mkdir(parents=True, exist_ok=True)
    OUT.write_text("\n".join(lines), encoding="utf-8")
    kb = OUT.stat().st_size // 1024
    print(f"Wrote {OUT} ({kb} KB, {len(files)} files)")


if __name__ == "__main__":
    build()
