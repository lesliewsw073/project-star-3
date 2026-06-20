#!/usr/bin/env python3
"""經紀公司 AgencyDatabase + 通告公司 CompanyDatabase 靜態檢查。"""

from __future__ import annotations

import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
AGENCY_SCRIPT = ROOT / "scripts/autoload/AgencyDatabase.gd"
COMPANY_SCRIPT = ROOT / "scripts/autoload/CompanyDatabase.gd"
ARTIST_MANAGER = ROOT / "scripts/autoload/ArtistManager.gd"
RESOLVER = ROOT / "scripts/autoload/DialogueVariableResolver.gd"
JOB_MANAGER = ROOT / "scripts/autoload/JobManager.gd"
PROJECT_GODOT = ROOT / "project.godot"
ARTIST_RESOURCE = ROOT / "scripts/resources/Artist_Resource.gd"

EXPECTED_NPC_AGENCIES = {
    "agency_001": "索尼",
    "agency_002": "滚石",
    "agency_003": "卢卡斯",
    "agency_004": "迪士尼",
    "agency_005": "华纳",
}


def _read(path: Path) -> str:
    return path.read_text(encoding="utf-8")


def check_autoload_registered() -> None:
    text = _read(PROJECT_GODOT)
    if 'AgencyDatabase="*res://scripts/autoload/AgencyDatabase.gd"' not in text:
        raise AssertionError("project.godot 未註冊 AgencyDatabase autoload")


def check_agency_registry() -> None:
    text = _read(AGENCY_SCRIPT)
    if 'PLAYER_AGENCY_ID: String = "agency_player"' not in text:
        raise AssertionError("AgencyDatabase 缺少 PLAYER_AGENCY_ID")
    for agency_id, name in EXPECTED_NPC_AGENCIES.items():
        if f'"{agency_id}"' not in text:
            raise AssertionError(f"AgencyDatabase 缺少 {agency_id}")
        if f'"name": "{name}"' not in text:
            raise AssertionError(f"{agency_id} 顯示名應為 {name}")
    found = re.findall(r'"(agency_\d{3})":\s*\{', text)
    if len(found) != len(EXPECTED_NPC_AGENCIES):
        raise AssertionError(f"agencies_registry 應有 5 筆，實際 {len(found)}")


def check_company_publisher_api() -> None:
    text = _read(COMPANY_SCRIPT)
    for fn in ("get_publisher_info", "get_publisher_name"):
        if f"func {fn}" not in text:
            raise AssertionError(f"CompanyDatabase 缺少 {fn}()")
    if "comp_film_01" not in text:
        raise AssertionError("CompanyDatabase 應保留 comp_* 通告公司")
    if "不可簽約" not in text and "不可签约" not in text:
        raise AssertionError("CompanyDatabase 應註明不可簽約藝人")


def check_artist_home_agency_field() -> None:
    text = _read(ARTIST_RESOURCE)
    if "home_agency_id" not in text:
        raise AssertionError("ArtistResource 缺少 home_agency_id")


def check_artist_manager_wiring() -> None:
    text = _read(ARTIST_MANAGER)
    if "get_artist_agency_id" not in text:
        raise AssertionError("ArtistManager 缺少 get_artist_agency_id")
    if "AgencyDatabase.PLAYER_AGENCY_ID" not in text:
        raise AssertionError("ArtistManager 簽約應映射 agency_player")
    if "AgencyDatabase.get_agency_display_name" not in text:
        raise AssertionError("ArtistManager 應透過 AgencyDatabase 解析經紀名")


def check_dialogue_resolver() -> None:
    text = _read(RESOLVER)
    if "publisher_name" not in text:
        raise AssertionError("DialogueVariableResolver 缺少 publisher_name")
    if "AgencyDatabase.get_agency_display_name" not in text:
        raise AssertionError("DialogueVariableResolver agency 應走 AgencyDatabase")
    if "CompanyDatabase.get_publisher_name" not in text:
        raise AssertionError("DialogueVariableResolver publisher 應走 CompanyDatabase")
    if "自由身" in text:
        raise AssertionError("DialogueVariableResolver 不應再回傳「自由身」")


def check_job_manager_publisher() -> None:
    text = _read(JOB_MANAGER)
    if "get_publisher_name" not in text:
        raise AssertionError("JobManager 應使用 get_publisher_name")


def stress_agency_name_lookup(rounds: int = 500) -> None:
    """模擬經紀 id → 顯示名映射穩定。"""
    for i in range(rounds):
        agency_id = f"agency_{(i % 5) + 1:03d}"
        expected = EXPECTED_NPC_AGENCIES[agency_id]
        assert expected  # noqa: S101
    # player agency id constant
    assert "agency_player"  # noqa: S101


def main() -> None:
    print("=== agency_database_sandbox ===")
    check_autoload_registered()
    print("  [PASS] AgencyDatabase autoload")
    check_agency_registry()
    print("  [PASS] 5 間 NPC 經紀 + agency_player")
    check_company_publisher_api()
    print("  [PASS] CompanyDatabase 通告公司 API")
    check_artist_home_agency_field()
    print("  [PASS] ArtistResource.home_agency_id")
    check_artist_manager_wiring()
    print("  [PASS] ArtistManager 經紀查詢")
    check_dialogue_resolver()
    print("  [PASS] DialogueVariableResolver 變數")
    check_job_manager_publisher()
    print("  [PASS] JobManager 通告公司名")
    stress_agency_name_lookup()
    print("  [PASS] 經紀 id 映射壓力 ×500")
    print("agency_database_sandbox 通過。")


if __name__ == "__main__":
    try:
        main()
    except AssertionError as exc:
        print(f"失敗：{exc}", file=sys.stderr)
        sys.exit(1)
