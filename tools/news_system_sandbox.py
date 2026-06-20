#!/usr/bin/env python3
"""新聞系統：記者 NPC、出道欄位、重大通告、每日頭條組裝。"""

from __future__ import annotations

import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
PROJECT = ROOT / "project.godot"
NEWS_MGR = ROOT / "scripts/autoload/NewsManager.gd"
REPORTER_MGR = ROOT / "scripts/autoload/ReporterManager.gd"
AWARD_REG = ROOT / "scripts/autoload/AwardRegistry.gd"
EDITION_BUILDER = ROOT / "scripts/news/NewsEditionBuilder.gd"
DAILY_PANEL = ROOT / "scripts/ui/DailyNewsPanel.gd"
GAME_FLOW = ROOT / "scripts/autoload/GameFlowManager.gd"
ARTIST_RES = ROOT / "scripts/resources/Artist_Resource.gd"
JOB_RES = ROOT / "scripts/resources/JobResource.gd"
DATA_NPCS = ROOT / "data/npcs"
ASSETS = ROOT / "assets/characters/npcs"
TEMPLATES = ROOT / "data/news/templates"


def _read(path: Path) -> str:
    return path.read_text(encoding="utf-8")


def check_autoloads() -> None:
    project = _read(PROJECT)
    for name in ("ReporterManager", "AwardRegistry", "NewsManager"):
        if f"{name}=" not in project:
            raise AssertionError(f"project.godot 未註冊 {name}")


def check_reporter_resources() -> None:
    for rid in ("reporter_01", "reporter_02"):
        tres = DATA_NPCS / rid / f"npc_{rid}.tres"
        if not tres.is_file():
            raise AssertionError(f"缺記者資源 {tres}")
        text = _read(tres)
        if f'npc_id = "{rid}"' not in text:
            raise AssertionError(f"{tres} npc_id 不符")
        if "is_test_content = true" not in text:
            raise AssertionError(f"{tres} 須標 is_test_content")
        for sub in ("avatar", "portrait", "cg"):
            if not (ASSETS / rid / sub).is_dir():
                raise AssertionError(f"缺記者視覺目錄 {ASSETS / rid / sub}")


def check_reporter_manager_api() -> None:
    text = _read(REPORTER_MGR)
    for token in ("reporter_01", "reporter_02", "get_paparazzi_id", "get_press_reporter_id"):
        if token not in text:
            raise AssertionError(f"ReporterManager 缺少 {token}")


def check_character_database_reporters() -> None:
    text = _read(ROOT / "scripts/autoload/CharacterDatabase.gd")
    if "CharacterKind.REPORTER" not in text:
        raise AssertionError("CharacterDatabase 缺 REPORTER kind")
    if "ReporterManager.is_reporter_id" not in text:
        raise AssertionError("CharacterDatabase 未接 ReporterManager")


def check_npc_manager_skips_reporters() -> None:
    text = _read(ROOT / "scripts/autoload/NpcManager.gd")
    for rid in ("reporter_01", "reporter_02"):
        if rid not in text:
            raise AssertionError(f"NpcManager 未排除 {rid}")


def check_artist_debut_field() -> None:
    text = _read(ARTIST_RES)
    if "is_debuted" not in text or "has_valid_debut_state" not in text:
        raise AssertionError("ArtistResource 缺 is_debuted / has_valid_debut_state")
    artists = sorted((ROOT / "data/artists").glob("artist_*/artist_*.tres"))
    if len(artists) != 16:
        raise AssertionError("artist 應 16 人")
    for p in artists:
        t = _read(p)
        if "is_debuted" not in t:
            raise AssertionError(f"{p} 缺 is_debuted")
        debuted = "is_debuted = true" in t
        agency = re.search(r'^home_agency_id = "(.*)"', t, re.M)
        agency_id = agency.group(1) if agency else ""
        if debuted and not agency_id:
            raise AssertionError(f"{p} 已出道但無 home_agency_id")
        if not debuted and agency_id:
            raise AssertionError(f"{p} 未出道卻有 home_agency_id")


def check_major_job_field() -> None:
    text = _read(JOB_RES)
    if "is_major_job" not in text:
        raise AssertionError("JobResource 缺 is_major_job")
    movie = ROOT / "data/jobs/test/test_job_movie_short_01.tres"
    if "is_major_job = true" not in _read(movie):
        raise AssertionError("test_job_movie_short_01 應標 is_major_job = true 作示例")


def check_news_edition_pipeline() -> None:
    for path in (NEWS_MGR, EDITION_BUILDER, DAILY_PANEL, GAME_FLOW, AWARD_REG):
        if not path.is_file():
            raise AssertionError(f"缺檔案 {path}")
    news = _read(NEWS_MGR)
    for token in (
        "EditionType",
        "build_daily_edition_for_today",
        "has_daily_edition_for_today",
        "queue_tabloid_story",
        "queue_artist_debut_news",
        "queue_major_job_preview",
    ):
        if token not in news:
            raise AssertionError(f"NewsManager 缺少 {token}")
    flow = _read(GAME_FLOW)
    for token in ("daily_news_requested", "dismiss_daily_news", "_try_begin_free_day_with_news"):
        if token not in flow:
            raise AssertionError(f"GameFlowManager 缺少 {token}")
    if not list(TEMPLATES.glob("*.tres")):
        raise AssertionError("缺 news filler 模板")


def main() -> None:
    check_autoloads()
    check_reporter_resources()
    check_reporter_manager_api()
    check_character_database_reporters()
    check_npc_manager_skips_reporters()
    check_artist_debut_field()
    check_major_job_field()
    check_news_edition_pipeline()
    print("news_system_sandbox: 全部檢查通過。")


if __name__ == "__main__":
    try:
        main()
    except AssertionError as exc:
        print(f"news_system_sandbox: 失敗 — {exc}", file=sys.stderr)
        sys.exit(1)
