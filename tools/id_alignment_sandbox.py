#!/usr/bin/env python3
"""角色 id、資料夾、劇本路徑、圖片目錄精準對齊檢查。"""

from __future__ import annotations

import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
ASSETS = ROOT / "assets/characters"
DATA_ARTISTS = ROOT / "data/artists"
DATA_RIVALS = ROOT / "data/rivals"
DATA_NPCS = ROOT / "data/npcs"
STORY_DIR = ROOT / "data/story_events"
WRITING_MAIN = ROOT / "docs/writing/02_Story_Events/1_Main_Story"
CHAR_MD = ROOT / "docs/writing/01_Characters"
VISUAL_PATHS = ROOT / "scripts/resources/CharacterVisualPaths.gd"

KNOWN_SPECIAL = {"protagonist", "secretary", "reporter_01", "reporter_02"}


def _read(path: Path) -> str:
    return path.read_text(encoding="utf-8")


def _field(text: str, name: str) -> str:
    m = re.search(rf'^{name}\s*=\s*"(.*)"', text, re.M)
    return m.group(1) if m else ""


def _collect_artist_ids() -> dict[str, Path]:
    out: dict[str, Path] = {}
    for folder in sorted(DATA_ARTISTS.glob("artist_*")):
        if not folder.is_dir():
            continue
        tres = folder / f"{folder.name}.tres"
        if not tres.is_file():
            raise AssertionError(f"缺 artist tres：{tres}")
        aid = _field(_read(tres), "artist_id")
        if aid != folder.name:
            raise AssertionError(f"artist 資料夾 {folder.name} vs artist_id={aid}")
        out[aid] = tres
    if len(out) != 16:
        raise AssertionError(f"artist 應 16 人，實際 {len(out)}")
    return out


def _collect_rival_ids() -> dict[str, Path]:
    out: dict[str, Path] = {}
    for folder in sorted(DATA_RIVALS.glob("rival_*")):
        if not folder.is_dir():
            continue
        tres = folder / f"{folder.name}.tres"
        aid = _field(_read(tres), "artist_id")
        if aid != folder.name:
            raise AssertionError(f"rival 資料夾 {folder.name} vs artist_id={aid}")
        out[aid] = tres
    if len(out) != 10:
        raise AssertionError(f"rival 應 10 人，實際 {len(out)}")
    return out


def _collect_npc_ids() -> dict[str, Path]:
    out: dict[str, Path] = {}
    for tres in sorted(DATA_NPCS.rglob("npc_*.tres")):
        if tres.name.startswith("seq_"):
            continue
        nid = _field(_read(tres), "npc_id")
        if not nid:
            raise AssertionError(f"{tres} 缺 npc_id")
        out[nid] = tres
    if "secretary" not in out:
        raise AssertionError("缺 secretary npc_secretary.tres")
    if "npc_shopkeeper_01" not in out:
        raise AssertionError("缺 npc_shopkeeper_01")
    for rid in ("reporter_01", "reporter_02"):
        if rid not in out:
            raise AssertionError(f"缺 {rid} npc_{rid}.tres")
    return out


def _expected_visual_base(character_id: str) -> Path:
    if character_id.startswith("artist_"):
        return ASSETS / "artists" / character_id
    if character_id.startswith("rival_"):
        return ASSETS / "rivals" / character_id
    return ASSETS / "npcs" / character_id


def check_data_folder_ids(artists: dict, rivals: dict, npcs: dict) -> None:
    for aid in artists:
        if artists[aid].parent.name != aid:
            raise AssertionError(f"artist 路徑未對齊 id：{artists[aid]}")
    for rid in rivals:
        if rivals[rid].parent.name != rid:
            raise AssertionError(f"rival 路徑未對齊 id：{rivals[rid]}")
    for nid, tres in npcs.items():
        if nid == "secretary":
            if tres.parent.name != "secretary":
                raise AssertionError(f"秘書資料夾應為 secretary：{tres}")
            continue
        if nid in ("reporter_01", "reporter_02"):
            if tres.parent.name != nid:
                raise AssertionError(f"記者資料夾應為 {nid}：{tres}")
            continue
        if not nid.startswith("npc_"):
            raise AssertionError(f"劇情 NPC id 應 npc_ 開頭：{nid}")
        if tres.parent.name != nid:
            raise AssertionError(f"NPC 資料夾 {tres.parent.name} vs npc_id={nid}")


def check_asset_folders(artists: dict, rivals: dict, npcs: dict) -> None:
    all_ids = set(artists) | set(rivals) | set(npcs)
    for cid in sorted(all_ids):
        base = _expected_visual_base(cid)
        if not base.is_dir():
            raise AssertionError(f"缺圖片根目錄 {base}（id={cid}）")
        for sub in ("avatar", "portrait", "cg"):
            if not (base / sub).is_dir():
                raise AssertionError(f"缺 {base / sub}")
        if (base / "avatars").is_dir():
            raise AssertionError(f"殘留舊目錄 avatars：{base}（應僅 avatar）")



def check_visual_path_api() -> None:
    text = _read(VISUAL_PATHS)
    for fn in ("avatar_path", "portrait_path", "cg_path", "get_character_bucket"):
        if fn not in text:
            raise AssertionError(f"CharacterVisualPaths 缺少 {fn}")

    samples = {
        "artist_003": "res://assets/characters/artists/artist_003/avatar/artist_003_avatar.png",
        "secretary": "res://assets/characters/npcs/secretary/avatar/secretary_avatar.png",
        "npc_shopkeeper_01": "res://assets/characters/npcs/npc_shopkeeper_01/avatar/npc_shopkeeper_01_avatar.png",
        "rival_001": "res://assets/characters/rivals/rival_001/avatar/rival_001_avatar.png",
    }
    for cid, expected in samples.items():
        if f'"{cid}"' not in text and expected.split("/")[-2] not in text:
            # 靜態驗證路徑組裝規則（與 GDScript 一致的手算）
            bucket = "artists" if cid.startswith("artist_") else "rivals" if cid.startswith("rival_") else "npcs"
            built = f"res://assets/characters/{bucket}/{cid}/avatar/{cid}_avatar.png"
            if built != expected:
                raise AssertionError(f"路徑規則異常 {cid}: {built}")


def check_story_events(known_ids: set[str]) -> None:
    for tres in sorted(STORY_DIR.rglob("*.tres")):
        text = _read(tres)
        rel = tres.relative_to(STORY_DIR)
        if not _field(text, "event_id"):
            raise AssertionError(f"{tres} 缺 event_id")

        if rel.parts[0] == "main" and len(rel.parts) >= 3 and rel.parts[1] == "artists":
            folder_artist = rel.parts[2]
            if not folder_artist.startswith("artist_"):
                raise AssertionError(f"主線資料夾命名異常：{tres}")
            for field in ("owner", "character_id"):
                val = _field(text, field)
                if val and val != folder_artist:
                    raise AssertionError(f"{tres} 路徑 {folder_artist} vs {field}={val}")
        elif rel.parts[0] == "main" and len(rel.parts) >= 2:
            folder_artist = rel.parts[1]
            if not folder_artist.startswith("artist_"):
                raise AssertionError(f"主線資料夾命名異常：{tres}")
            for field in ("owner", "character_id"):
                val = _field(text, field)
                if val and val != folder_artist:
                    raise AssertionError(f"{tres} 路徑 {folder_artist} vs {field}={val}")

        for field in ("owner", "character_id"):
            val = _field(text, field)
            if val and val not in known_ids and not val.startswith(("duo:", "ensemble:")):
                raise AssertionError(f"{tres} 未知 {field}={val}")

        for sid in re.findall(r'^speaker_id\s*=\s*"(.*)"', text, re.M):
            if sid and sid not in known_ids:
                raise AssertionError(f"{tres} 未知 speaker_id={sid}")


def check_writing_godot_resource(artists: dict) -> None:
    if not WRITING_MAIN.is_dir():
        return
    for md in sorted(WRITING_MAIN.rglob("*.md")):
        text = _read(md)
        m = re.search(r"^godot_resource:\s*(res://\S+)", text, re.M)
        if not m:
            continue
        rel = m.group(1).replace("res://", "")
        target = ROOT / rel
        if not target.is_file():
            raise AssertionError(f"{md.name} godot_resource 不存在：{rel}")
        # main/artist_NNN 資料夾與 owner 對齊
        parts = Path(rel).parts
        if len(parts) >= 5 and parts[1] == "story_events" and parts[2] == "main" and parts[3] == "artists":
            folder_artist = parts[4]
            owner_m = re.search(r"^owner:\s*(\S+)", text, re.M)
            if owner_m and owner_m.group(1) != folder_artist:
                raise AssertionError(f"{md.name} owner 与文件夹不一致")
        elif len(parts) >= 4 and parts[1] == "story_events" and parts[2] == "main":
            folder_artist = parts[3]
            if folder_artist in artists:
                tres_text = _read(target)
                for field in ("owner", "character_id"):
                    val = _field(tres_text, field)
                    if val and val != folder_artist:
                        raise AssertionError(f"{md.name} ↔ {target.name} {field}={val} ≠ {folder_artist}")


def check_character_md_portraits(artists: dict) -> None:
    for aid in ("artist_001", "artist_002", "artist_003"):
        md = CHAR_MD / f"{aid}.md"
        if not md.is_file():
            raise AssertionError(f"缺人設檔 {md}")
        expected = f"assets/characters/artists/{aid}/portrait/{aid}_portrait.png"
        if expected not in _read(md):
            raise AssertionError(f"{md} portrait 路徑應含 {expected}")


def main() -> None:
    artists = _collect_artist_ids()
    rivals = _collect_rival_ids()
    npcs = _collect_npc_ids()
    known_ids = set(artists) | set(rivals) | KNOWN_SPECIAL | set(npcs)

    check_data_folder_ids(artists, rivals, npcs)
    check_asset_folders(artists, rivals, npcs)
    check_visual_path_api()
    check_story_events(known_ids)
    check_writing_godot_resource(artists)
    check_character_md_portraits(artists)
    print("id_alignment_sandbox: 全部檢查通過。")


if __name__ == "__main__":
    try:
        main()
    except AssertionError as exc:
        print(f"id_alignment_sandbox: 失敗 — {exc}", file=sys.stderr)
        sys.exit(1)
