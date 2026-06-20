#!/usr/bin/env python3
"""NpcManager：劇情 NPC（npc_*）與 CharacterDatabase 整合檢查。"""

from __future__ import annotations

import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
NPC_MGR = ROOT / "scripts/autoload/NpcManager.gd"
CHAR_DB = ROOT / "scripts/autoload/CharacterDatabase.gd"
NPC_RES = ROOT / "scripts/resources/NPCResource.gd"
SECRETARY = ROOT / "scripts/autoload/SecretaryManager.gd"
RESOLVER = ROOT / "scripts/autoload/DialogueVariableResolver.gd"
PROJECT = ROOT / "project.godot"
NPCS_DIR = ROOT / "data/npcs"
SECRETARY_TRES = ROOT / "data/npcs/secretary/npc_secretary.tres"
FACILITIES_DIR = ROOT / "data/facilities"

DEFAULT_AFFECTION = 10


def _read(path: Path) -> str:
    return path.read_text(encoding="utf-8")


def _parse_npc_tres(path: Path) -> dict:
    text = _read(path)
    out: dict = {"path": path}
    m = re.search(r'^npc_id\s*=\s*"(.*)"', text, re.M)
    out["npc_id"] = m.group(1) if m else ""
    m_name = re.search(r'^npc_name\s*=\s*"(.*)"', text, re.M)
    out["npc_name"] = m_name.group(1) if m_name else ""
    out["type_story"] = re.search(r"^type\s*=\s*1", text, re.M) is not None
    out["can_gain_affection"] = "can_gain_affection = true" in text
    m_aff = re.search(r"^default_affection\s*=\s*(\d+)", text, re.M)
    out["default_affection"] = int(m_aff.group(1)) if m_aff else None
    m_fac = re.search(r'^home_facility_id\s*=\s*"(.*)"', text, re.M)
    out["home_facility_id"] = m_fac.group(1) if m_fac else ""
    out["has_dialogue"] = "default_dialogue" in text
    npc_id = out.get("npc_id", "")
    visual_avatar_dir = ROOT / "assets/characters/npcs" / npc_id / "avatar"
    out["has_portrait"] = visual_avatar_dir.is_dir() or "portrait" in text or "avatar" in text
    return out


def load_all_npc_tres() -> list[dict]:
    paths = sorted(NPCS_DIR.glob("**/npc_*.tres"))
    return [_parse_npc_tres(p) for p in paths]


def check_autoload() -> None:
    project = _read(PROJECT)
    if "NpcManager=" not in project:
        raise AssertionError("project.godot 未註冊 NpcManager")
    npc_line = [ln for ln in project.splitlines() if "NpcManager=" in ln][0]
    char_line = [ln for ln in project.splitlines() if "CharacterDatabase=" in ln][0]
    if project.index(npc_line) > project.index(char_line):
        raise AssertionError("NpcManager 應在 CharacterDatabase 之前 autoload")


def check_npc_manager_api() -> None:
    text = _read(NPC_MGR)
    for fn in (
        "load_all_npcs",
        "is_story_npc_id",
        "get_npc_resource",
        "get_all_npc_ids",
        "get_npc_display_name",
        "get_npc_portrait",
        "get_npc_initial_affection",
    ):
        if f"func {fn}" not in text:
            raise AssertionError(f"NpcManager 缺少 {fn}()")
    if 'npc_id == SECRETARY_ID' not in text and "secretary" not in text:
        raise AssertionError("NpcManager 應排除 secretary")


def check_character_database_npc_integration() -> None:
    text = _read(CHAR_DB)
    if "NpcManager.is_story_npc_id" not in text:
        raise AssertionError("CharacterDatabase 應辨識 npc_*")
    if "is_story_npc" not in text:
        raise AssertionError("CharacterDatabase 缺少 is_story_npc()")
    if "NpcManager.get_all_npc_ids()" not in text:
        raise AssertionError("CharacterDatabase 應登記 npc 好感")
    if "CharacterKind.STORY_NPC" not in text:
        raise AssertionError("CharacterDatabase 應處理 STORY_NPC 顯示名／頭像")


def check_npc_resource_fields() -> None:
    text = _read(NPC_RES)
    for field in ("home_facility_id", "can_gain_affection", "default_affection"):
        if f"var {field}" not in text:
            raise AssertionError(f"NPCResource 缺少 {field}")
    if "default_affection: int = 10" not in text:
        raise AssertionError("NPCResource default_affection 預設應為 10")


def check_secretary_separate() -> None:
    sec = _parse_npc_tres(SECRETARY_TRES)
    if sec["npc_id"] != "secretary":
        raise AssertionError("秘書 npc_id 應為 secretary")
    if "RelationshipManager.register_character" in _read(SECRETARY):
        raise AssertionError("SecretaryManager 不應自行 register")


def check_story_npcs(npcs: list[dict]) -> None:
    story_npcs = [n for n in npcs if n["npc_id"].startswith("npc_")]
    if len(story_npcs) < 1:
        raise AssertionError("至少應有 1 位 npc_* 劇情 NPC")

    for npc in story_npcs:
        npc_id = npc["npc_id"]
        if not npc_id.startswith("npc_"):
            raise AssertionError(f"{npc_id} 必須 npc_ 前綴")
        if npc_id == "secretary":
            raise AssertionError("secretary 不應使用 npc_ 前綴")
        if not npc["type_story"]:
            raise AssertionError(f"{npc_id} type 應為 STORY(1)")
        if not npc["can_gain_affection"]:
            raise AssertionError(f"{npc_id} 劇情 NPC 應開啟 can_gain_affection")
        aff = npc["default_affection"]
        if aff is None or aff != DEFAULT_AFFECTION:
            raise AssertionError(f"{npc_id} default_affection 應為 {DEFAULT_AFFECTION}，實際 {aff}")

    shop = next((n for n in story_npcs if n["npc_id"] == "npc_shopkeeper_01"), None)
    if shop is None:
        raise AssertionError("缺少 npc_shopkeeper_01")
    if shop["home_facility_id"] != "fac_shop":
        raise AssertionError("商店老闆 home_facility_id 應為 fac_shop")
    if not shop["has_dialogue"]:
        raise AssertionError("商店老闆應有 default_dialogue")
    if not shop["has_portrait"]:
        raise AssertionError("商店老闆應有頭像")


def check_facility_npc_refs() -> None:
    """設施引用的 npc tres 必須在 NpcManager 可載入的 npc_* 名單內。"""
    known_ids = {n["npc_id"] for n in load_all_npc_tres() if n["npc_id"].startswith("npc_")}
    for fac_path in sorted(FACILITIES_DIR.glob("**/*.tres")):
        text = _read(fac_path)
        npc_paths = re.findall(r'path="(res://data/npcs/[^"]+)"', text)
        for rel in npc_paths:
            npc_path = ROOT / rel.replace("res://", "")
            if not npc_path.exists():
                raise AssertionError(f"{fac_path.name} 引用不存在的 NPC：{rel}")
            npc = _parse_npc_tres(npc_path)
            if npc["npc_id"] not in known_ids:
                raise AssertionError(f"{fac_path.name} 引用未知 npc_id：{npc['npc_id']}")


def check_dialogue_resolver() -> None:
    text = _read(RESOLVER)
    if "NpcManager.get_npc_resource" not in text:
        raise AssertionError("DialogueVariableResolver 應支援 npc_name")
    if '"npc_name"' not in text:
        raise AssertionError("DialogueVariableResolver 應輸出 npc_name 變數")


def main() -> None:
    print("=== npc_database_sandbox ===")
    npcs = load_all_npc_tres()
    check_autoload()
    print("  [PASS] NpcManager autoload 順序")
    check_npc_manager_api()
    print("  [PASS] NpcManager API")
    check_npc_resource_fields()
    print("  [PASS] NPCResource 欄位")
    check_character_database_npc_integration()
    print("  [PASS] CharacterDatabase NPC 整合")
    check_secretary_separate()
    print("  [PASS] 秘書獨立於 NpcManager")
    check_story_npcs(npcs)
    print(f"  [PASS] {len([n for n in npcs if n['npc_id'].startswith('npc_')])} 位劇情 NPC")
    check_facility_npc_refs()
    print("  [PASS] 設施 NPC 引用")
    check_dialogue_resolver()
    print("  [PASS] DialogueVariableResolver")
    print("npc_database_sandbox 通過。")


if __name__ == "__main__":
    try:
        main()
    except AssertionError as exc:
        print(f"失敗：{exc}", file=sys.stderr)
        sys.exit(1)
