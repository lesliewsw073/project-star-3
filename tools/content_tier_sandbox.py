#!/usr/bin/env python3
"""內容分級標記：資源欄位、登記表、專案規則。"""

from __future__ import annotations

import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
DATA = ROOT / "data"
REGISTRY = ROOT / "docs/writing/CONTENT_TIER_REGISTRY.md"
RULE = ROOT / ".cursor/rules/test-content-marking.mdc"

CANONICAL_ARTIST = "artist_003"
CANONICAL_EVENT_DIR = DATA / "story_events/main/artists/artist_003"
SECRETARY_NPC = DATA / "npcs/secretary/npc_secretary.tres"

RESOURCE_SCRIPTS = [
    "JobResource.gd",
    "GigResource.gd",
    "CourseResource.gd",
    "ItemResource.gd",
    "VacationResource.gd",
    "InteractionEventResource.gd",
    "Artist_Resource.gd",
    "NPCResource.gd",
]

TEST_GIG = "酒吧駐唱"
TEST_COURSE = "影視表演基礎班"


def _read(path: Path) -> str:
    return path.read_text(encoding="utf-8")


def _tres_flag(path: Path, field: str) -> bool | None:
    m = re.search(rf"^{field} = (true|false)", _read(path), re.M)
    if m is None:
        return None
    return m.group(1) == "true"


def _tres_quoted(path: Path, field: str) -> str | None:
    m = re.search(rf'^{field} = "(.*)"', _read(path), re.M)
    return m.group(1) if m else None


def check_resource_scripts() -> None:
    for name in RESOURCE_SCRIPTS:
        path = ROOT / "scripts/resources" / name
        if "is_test_content" not in _read(path):
            raise AssertionError(f"{name} 缺少 is_test_content")


def check_registry_and_rule() -> None:
    if not REGISTRY.is_file():
        raise AssertionError("缺少 CONTENT_TIER_REGISTRY.md")
    if not RULE.is_file():
        raise AssertionError("缺少 test-content-marking.mdc")
    reg = _read(REGISTRY)
    if CANONICAL_ARTIST not in reg or "is_test_content = false" not in reg:
        raise AssertionError("登記表未標記正式稿")
    if "test_job_movie_short_01" not in reg:
        raise AssertionError("登記表未收錄邀請接案測試通告")


def check_canonical_artist() -> None:
    path = DATA / "artists" / CANONICAL_ARTIST / f"{CANONICAL_ARTIST}.tres"
    if _tres_flag(path, "is_test_content") is not False:
        raise AssertionError(f"{CANONICAL_ARTIST} 應為正式稿 is_test_content=false")


def check_placeholder_artists() -> None:
    for p in (DATA / "artists").glob("artist_*/artist_*.tres"):
        if p.parent.name == CANONICAL_ARTIST:
            continue
        if _tres_flag(p, "is_test_content") is not True:
            raise AssertionError(f"{p.parent.name} 占位藝人應 is_test_content=true")


def check_jobs_test_folder() -> None:
    for p in (DATA / "jobs/test").glob("*.tres"):
        text = _read(p)
        if _tres_flag(p, "is_test_content") is not True:
            raise AssertionError(f"{p.name} 應 is_test_content=true")
        name = _tres_quoted(p, "job_name") or ""
        if not name:
            raise AssertionError(f"{p.name} job_name 不應為空")


def check_activity_templates() -> None:
    gig = DATA / "gigs/gig_bar_singer_01.tres"
    if _tres_quoted(gig, "gig_name") != TEST_GIG:
        raise AssertionError("gig 顯示名不一致")
    if _tres_flag(gig, "is_test_content") is not True:
        raise AssertionError("gig 應 is_test_content=true")
    course = DATA / "courses/course_acting_basic_01.tres"
    if _tres_quoted(course, "course_name") != TEST_COURSE:
        raise AssertionError("course 顯示名不一致")


def check_story_events() -> None:
    for p in DATA.glob("story_events/**/*.tres"):
        if CANONICAL_EVENT_DIR in p.parents:
            if _tres_flag(p, "is_test_content") is not False:
                raise AssertionError(f"米语劇本 {p.name} 應 is_test_content=false")
            continue
        if _tres_flag(p, "is_test_content") is not True:
            raise AssertionError(f"占位劇本 {p} 應 is_test_content=true")
        title = _tres_quoted(p, "event_title") or ""
        if not title:
            raise AssertionError(f"{p.name} event_title 不應為空")


def check_secretary() -> None:
    if _tres_flag(SECRETARY_NPC, "is_test_content") is not False:
        raise AssertionError("秘書應為正式角色 is_test_content=false")


def check_job_manager_summary() -> None:
    if '"is_test_content": job.is_test_content' not in _read(ROOT / "scripts/autoload/JobManager.gd"):
        raise AssertionError("JobManager summary 未輸出 is_test_content")


def main() -> None:
    check_resource_scripts()
    check_registry_and_rule()
    check_canonical_artist()
    check_placeholder_artists()
    check_jobs_test_folder()
    check_activity_templates()
    check_story_events()
    check_secretary()
    check_job_manager_summary()
    print("content_tier_sandbox: 全部檢查通過。")


if __name__ == "__main__":
    try:
        main()
    except AssertionError as exc:
        print(f"content_tier_sandbox: 失敗 — {exc}", file=sys.stderr)
        sys.exit(1)
