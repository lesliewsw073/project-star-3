#!/usr/bin/env python3
"""角色視覺資源目錄與路徑約定檢查。"""

from __future__ import annotations

import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
PATHS = ROOT / "scripts/resources/CharacterVisualPaths.gd"
DIALOGUE = ROOT / "scripts/controllers/dialogue_panel.gd"
README = ROOT / "docs/writing/README_CHARACTER_ASSETS.md"
ASSETS = ROOT / "assets/characters"


def _read(path: Path) -> str:
    return path.read_text(encoding="utf-8")


def check_paths_api() -> None:
    text = _read(PATHS)
    for token in ("avatar_path", "portrait_path", "cg_path", "try_load_texture"):
        if token not in text:
            raise AssertionError(f"CharacterVisualPaths 缺少 {token}")


def check_character_database() -> None:
    text = _read(ROOT / "scripts/autoload/CharacterDatabase.gd")
    for token in ("get_avatar", "get_cg_texture"):
        if token not in text:
            raise AssertionError(f"CharacterDatabase 缺少 {token}")


def check_dialogue_cg() -> None:
    text = _read(DIALOGUE)
    for token in ("cg_rect", "portrait_left_rect", "portrait_right_rect", "get_cg_texture", "get_portrait"):
        if token not in text:
            raise AssertionError(f"DialoguePanel 缺少 CG/立繪接線：{token}")


def check_folder_layout() -> None:
    for i in range(1, 17):
        aid = f"artist_{i:03d}"
        base = ASSETS / "artists" / aid
        for sub in ("avatar", "portrait", "cg"):
            if not (base / sub).is_dir():
                raise AssertionError(f"缺少目錄 {base / sub}")
        if (base / "avatars").is_dir():
            raise AssertionError(f"殘留舊目錄 avatars：{base}（應僅 avatar）")
    for npc in ("secretary", "npc_shopkeeper_01", "reporter_01", "reporter_02"):
        base = ASSETS / "npcs" / npc
        for sub in ("avatar", "portrait", "cg"):
            if not (base / sub).is_dir():
                raise AssertionError(f"缺少目錄 {base / sub}")
        if (base / "avatars").is_dir():
            raise AssertionError(f"殘留舊目錄 avatars：{base}")


def check_no_legacy_portraits() -> None:
    if list(ASSETS.rglob("portraits")):
        raise AssertionError("仍存在舊 portraits 目錄")
    if (ASSETS / "imported").exists():
        raise AssertionError("仍存在 imported 暫存目錄")
    for base in ASSETS.rglob("avatars"):
        if base.is_dir():
            raise AssertionError(f"殘留舊目錄 avatars：{base}（應僅 avatar）")


def check_deployed_character_pngs() -> None:
    expected = [
        ("artists/artist_001/avatar/artist_001_avatar.png", "artist_001 avatar"),
        ("artists/artist_001/portrait/artist_001_portrait.png", "artist_001 portrait"),
        ("artists/artist_003/avatar/artist_003_avatar.png", "artist_003 avatar"),
        ("npcs/npc_shopkeeper_01/avatar/npc_shopkeeper_01_avatar.png", "shopkeeper avatar"),
    ]
    for rel, label in expected:
        if not (ASSETS / rel).is_file():
            raise AssertionError(f"缺已投放角色圖：{label} ({rel})")


def check_readme() -> None:
    text = _read(README)
    for token in ("512×512", "900×1400", "1600×900", "artist_NNN_avatar", "artist_NNN_portrait", "artist_NNN_cg_"):
        if token not in text:
            raise AssertionError(f"README_CHARACTER_ASSETS 缺少 {token}")


def main() -> None:
    check_paths_api()
    check_character_database()
    check_dialogue_cg()
    check_folder_layout()
    check_no_legacy_portraits()
    check_deployed_character_pngs()
    check_readme()
    print("character_assets_sandbox: 全部檢查通過。")


if __name__ == "__main__":
    try:
        main()
    except AssertionError as exc:
        print(f"character_assets_sandbox: 失敗 — {exc}", file=sys.stderr)
        sys.exit(1)
