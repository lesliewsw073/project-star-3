#!/usr/bin/env python3
"""CharacterDatabase：16 人我方藝人 + rival_NNN 競爭對手檢查。"""

from __future__ import annotations

import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
CHAR_DB = ROOT / "scripts/autoload/CharacterDatabase.gd"
RIVAL_MGR = ROOT / "scripts/autoload/RivalManager.gd"
SECRETARY = ROOT / "scripts/autoload/SecretaryManager.gd"
ARTIST_MGR = ROOT / "scripts/autoload/ArtistManager.gd"
ARTIST_RES = ROOT / "scripts/resources/Artist_Resource.gd"
PROJECT = ROOT / "project.godot"
SECRETARY_TRES = ROOT / "data/npcs/secretary/npc_secretary.tres"
ARTISTS_DIR = ROOT / "data/artists"
RIVALS_DIR = ROOT / "data/rivals"

EXPECTED_AGENCY_ARTISTS = 16
EXPECTED_RIVALS = 10
EXPECTED_OPENING = 3
EXPECTED_POACH_OUT = 1  # artist_002
EXPECTED_POACH_IN = 2  # sibling pair 005/006
EXPECTED_FIXED_JOIN = 1  # artist_004 among 004-016
SIBLING_PAIR = ("artist_005", "artist_006")
VALID_AGENCIES = {f"agency_{i:03d}" for i in range(1, 6)}


def _read(path: Path) -> str:
    return path.read_text(encoding="utf-8")


def _parse_performer_tres(path: Path) -> dict:
    text = _read(path)
    out: dict = {"path": path}
    m = re.search(r'^artist_id\s*=\s*"(.*)"', text, re.M)
    out["artist_id"] = m.group(1) if m else ""
    out["opening_pick"] = "opening_pick = true" in text
    out["poachable_in"] = "poachable_in = true" in text
    out["poachable_out"] = "poachable_out = true" in text
    out["fixed_story_join"] = "fixed_story_join = true" in text
    out["has_stats"] = bool(re.search(r"^acting\s*=\s*\d+", text, re.M))
    training_mod_fields = (
        "contract_diff_mod",
        "fail_rate_abs",
        "perfect_rate_abs",
        "morality_mod",
        "favor_gain_mod",
        "stress_gain_mod",
        "fatigue_gain_mod",
        "satisfaction_gain_mod",
    )
    out["has_training_mods"] = all(
        re.search(rf"^{field}\s*=", text, re.M) for field in training_mod_fields
    )
    m_ag = re.search(r'^home_agency_id\s*=\s*"(.*)"', text, re.M)
    out["home_agency_id"] = m_ag.group(1) if m_ag else ""
    m_sib = re.search(r'^sibling_partner_id\s*=\s*"(.*)"', text, re.M)
    out["sibling_partner_id"] = m_sib.group(1) if m_sib else ""
    return out


def load_all_artists() -> list[dict]:
    paths = sorted(ARTISTS_DIR.glob("artist_*/artist_*.tres"))
    return [_parse_performer_tres(p) for p in paths]


def load_all_rivals() -> list[dict]:
    paths = sorted(RIVALS_DIR.glob("rival_*/rival_*.tres"))
    return [_parse_performer_tres(p) for p in paths]


def check_autoload() -> None:
    project = _read(PROJECT)
    if "CharacterDatabase=" not in project:
        raise AssertionError("project.godot 未註冊 CharacterDatabase")
    if "RivalManager=" not in project:
        raise AssertionError("project.godot 未註冊 RivalManager")
    if "ReporterManager=" not in project:
        raise AssertionError("project.godot 未註冊 ReporterManager")


def check_character_database_api() -> None:
    text = _read(CHAR_DB)
    for fn in (
        "get_kind",
        "get_display_name",
        "get_portrait",
        "get_initial_affection",
        "is_agency_artist",
        "is_rival",
        "is_story_npc",
        "get_role_label",
        "get_performer_resource",
        "get_npc_resource",
    ):
        if f"func {fn}" not in text:
            raise AssertionError(f"CharacterDatabase 缺少 {fn}()")
    if "CharacterKind.RIVAL" not in text:
        raise AssertionError("CharacterDatabase 應有 CharacterKind.RIVAL")
    if "CharacterKind.REPORTER" not in text:
        raise AssertionError("CharacterDatabase 應有 CharacterKind.REPORTER")
    if "RivalManager.get_all_rival_ids()" not in text:
        raise AssertionError("CharacterDatabase 應登記全部 rival 好感")
    if "NpcManager.get_all_npc_ids()" not in text:
        raise AssertionError("CharacterDatabase 應登記 npc 好感")


def check_rival_manager_api() -> None:
    text = _read(RIVAL_MGR)
    for fn in (
        "load_all_rivals",
        "is_rival_id",
        "get_rival_resource",
        "get_all_rival_ids",
    ):
        if f"func {fn}" not in text:
            raise AssertionError(f"RivalManager 缺少 {fn}()")


def check_artist_manager_queries() -> None:
    text = _read(ARTIST_MGR)
    for fn in (
        "get_agency_artist_ids",
        "get_fixed_story_join_artist_ids",
        "get_poachable_in_artist_ids",
        "get_poachable_out_artist_ids",
        "get_sibling_partner_id",
        "can_player_sign_artist",
        "sign_artist_via_story",
    ):
        if f"func {fn}" not in text:
            raise AssertionError(f"ArtistManager 缺少 {fn}()")
    if "is_ecosystem_artist" in text:
        raise AssertionError("ArtistManager 不應再保留 is_ecosystem_artist")
    if "is_player_pool" in text:
        raise AssertionError("ArtistManager 不應再引用 is_player_pool")
    if "RivalManager.is_rival_id" not in text:
        raise AssertionError("can_player_sign_artist 應擋 rival_*")


def check_artist_resource_fields() -> None:
    text = _read(ARTIST_RES)
    if "is_player_pool" in text:
        raise AssertionError("ArtistResource 不應再保留 is_player_pool")
    for field in (
        "opening_pick",
        "poachable_in",
        "poachable_out",
        "fixed_story_join",
        "sibling_partner_id",
        "home_agency_id",
    ):
        if f"var {field}" not in text:
            raise AssertionError(f"ArtistResource 缺少 {field}")
    for field in (
        "contract_diff_mod",
        "fail_rate_abs",
        "perfect_rate_abs",
        "morality_mod",
        "favor_gain_mod",
        "stress_gain_mod",
        "fatigue_gain_mod",
        "satisfaction_gain_mod",
    ):
        if f"var {field}" not in text:
            raise AssertionError(f"ArtistResource 缺少 {field}")


def check_sixteen_agency_artists(artists: list[dict]) -> None:
    if len(artists) != EXPECTED_AGENCY_ARTISTS:
        raise AssertionError(f"應有 {EXPECTED_AGENCY_ARTISTS} 位我方藝人，實際 {len(artists)}")

    ids = [a["artist_id"] for a in artists]
    expected_ids = [f"artist_{i:03d}" for i in range(1, 17)]
    if ids != expected_ids:
        raise AssertionError(f"artist_id 應為 artist_001～artist_016 連續，實際 {ids}")

    for a in artists:
        if not a["artist_id"].startswith("artist_"):
            raise AssertionError(f"{a['artist_id']} 必須為 artist_*")

    opening = [a for a in artists if a["opening_pick"]]
    if len(opening) != EXPECTED_OPENING:
        raise AssertionError(f"opening_pick 應 {EXPECTED_OPENING} 人")

    poach_out = [a for a in artists if a["poachable_out"]]
    if len(poach_out) != EXPECTED_POACH_OUT or poach_out[0]["artist_id"] != "artist_002":
        raise AssertionError("被挖走應僅 artist_002")

    poach_in = [a for a in artists if a["poachable_in"]]
    if len(poach_in) != EXPECTED_POACH_IN:
        raise AssertionError(f"挖角加入應 {EXPECTED_POACH_IN} 人")
    poach_in_ids = {a["artist_id"] for a in poach_in}
    if poach_in_ids != set(SIBLING_PAIR):
        raise AssertionError(f"挖角組合應為 {SIBLING_PAIR}，實際 {poach_in_ids}")

    a005 = next(a for a in artists if a["artist_id"] == "artist_005")
    a006 = next(a for a in artists if a["artist_id"] == "artist_006")
    if a005["sibling_partner_id"] != "artist_006" or a006["sibling_partner_id"] != "artist_005":
        raise AssertionError("兄妹／姐弟組合 sibling_partner_id 未互相引用")

    fixed_join = [a for a in artists if a["fixed_story_join"]]
    if len(fixed_join) != EXPECTED_FIXED_JOIN or fixed_join[0]["artist_id"] != "artist_004":
        raise AssertionError("004～016 固定劇情加入應僅 artist_004")

    for a in artists:
        num = int(a["artist_id"].split("_")[1])
        if 4 <= num <= 16 and a["fixed_story_join"] and a["artist_id"] != "artist_004":
            raise AssertionError(f"{a['artist_id']} 不應標 fixed_story_join")

    # 007-016 為我方占位，不應帶競爭用能力值
    for a in artists:
        num = int(a["artist_id"].split("_")[1])
        if num >= 7 and a["has_stats"]:
            raise AssertionError(f"{a['artist_id']} 我方占位不應預填 acting 等能力值")

    for a in artists:
        agency = a["home_agency_id"]
        num = int(a["artist_id"].split("_")[1])
        if num <= 3:
            if agency != "" and agency not in VALID_AGENCIES:
                raise AssertionError(f"{a['artist_id']} home_agency_id 無效：{agency!r}")
            continue
        if num <= 6:
            if agency == "" or agency not in VALID_AGENCIES:
                raise AssertionError(f"{a['artist_id']} home_agency_id 無效：{agency!r}")
            continue
        # 007-016 劇情加入前可不掛經紀
        if agency != "" and agency not in VALID_AGENCIES:
            raise AssertionError(f"{a['artist_id']} home_agency_id 無效：{agency!r}")

    if a005["home_agency_id"] != a006["home_agency_id"]:
        raise AssertionError("挖角兄妹應掛同一經紀公司")

    for a in artists:
        if not a["has_training_mods"]:
            raise AssertionError(f"{a['artist_id']} 缺少養成修正欄位（contract_diff_mod 等）")


def check_rivals(rivals: list[dict]) -> None:
    if len(rivals) != EXPECTED_RIVALS:
        raise AssertionError(f"應有 {EXPECTED_RIVALS} 位 rival，實際 {len(rivals)}")

    ids = [r["artist_id"] for r in rivals]
    expected = [f"rival_{i:03d}" for i in range(1, 11)]
    if ids != expected:
        raise AssertionError(f"rival id 應為 rival_001～rival_010，實際 {ids}")

    for r in rivals:
        if not r["artist_id"].startswith("rival_"):
            raise AssertionError(f"{r['artist_id']} 必須為 rival_*")
        if not r["has_stats"]:
            raise AssertionError(f"{r['artist_id']} 缺少能力值（通告競爭用）")
        if not r["has_training_mods"]:
            raise AssertionError(f"{r['artist_id']} 缺少養成修正欄位（contract_diff_mod 等）")
        agency = r["home_agency_id"]
        if agency == "" or agency not in VALID_AGENCIES:
            raise AssertionError(f"{r['artist_id']} 必須掛 NPC 經紀：{agency!r}")


def check_secretary() -> None:
    text = _read(SECRETARY_TRES)
    if 'npc_id = "secretary"' not in text:
        raise AssertionError("npc_secretary.tres npc_id 應為 secretary")
    if 'npc_name = "小唯"' not in text:
        raise AssertionError("npc_secretary.tres npc_name 應為 小唯")
    if "RelationshipManager.register_character" in _read(SECRETARY):
        raise AssertionError("SecretaryManager 不應自行 register")


def check_game_root() -> None:
    if "CharacterDatabase.get_display_name" not in _read(ROOT / "scripts/controllers/GameRootController.gd"):
        raise AssertionError("GameRootController 應使用 CharacterDatabase")


def main() -> None:
    print("=== character_database_sandbox ===")
    artists = load_all_artists()
    rivals = load_all_rivals()
    check_autoload()
    print("  [PASS] CharacterDatabase + RivalManager autoload")
    check_character_database_api()
    print("  [PASS] CharacterDatabase API")
    check_rival_manager_api()
    print("  [PASS] RivalManager API")
    check_artist_manager_queries()
    print("  [PASS] ArtistManager 簽約／劇情 API")
    check_artist_resource_fields()
    print("  [PASS] ArtistResource 欄位")
    check_sixteen_agency_artists(artists)
    print("  [PASS] 16 位我方藝人（artist_001～016）")
    check_rivals(rivals)
    print("  [PASS] 10 位競爭對手（rival_001～010）")
    check_secretary()
    print("  [PASS] 秘書")
    check_game_root()
    print("  [PASS] GameRootController")
    print("character_database_sandbox 通過。")


if __name__ == "__main__":
    try:
        main()
    except AssertionError as exc:
        print(f"失敗：{exc}", file=sys.stderr)
        sys.exit(1)
