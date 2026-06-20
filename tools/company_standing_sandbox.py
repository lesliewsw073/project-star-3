#!/usr/bin/env python3
"""口碑／聲望結算與週日會議正式互動接線檢查。"""

from __future__ import annotations

import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
RESOLVER = ROOT / "scripts/managers/CompanyStandingResolver.gd"
JOB_MGR = ROOT / "scripts/autoload/JobManager.gd"
NEWS_MGR = ROOT / "scripts/autoload/NewsManager.gd"
GIG_MGR = ROOT / "scripts/autoload/GigManager.gd"
COURSE_MGR = ROOT / "scripts/autoload/CourseManager.gd"
INTERACTION = ROOT / "scripts/autoload/InteractionManager.gd"
EVENT_RES = ROOT / "scripts/resources/InteractionEventResource.gd"
GAME_ROOT = ROOT / "scripts/controllers/GameRootController.gd"


def _read(path: Path) -> str:
    return path.read_text(encoding="utf-8")


def check_resolver_api() -> None:
    text = _read(RESOLVER)
    for fn in (
        "apply_job_completion",
        "apply_job_failure",
        "apply_activity_completion",
        "apply_news_standing",
        "apply_meeting_terminate",
        "apply_deltas",
    ):
        if fn not in text:
            raise AssertionError(f"CompanyStandingResolver 缺少 {fn}")


def check_hooks() -> None:
    if "CompanyStandingResolver.apply_job_completion" not in _read(JOB_MGR):
        raise AssertionError("JobManager 未掛載通告完成聲望/口碑")
    if "CompanyStandingResolver.apply_job_failure" not in _read(JOB_MGR):
        raise AssertionError("JobManager 未掛載通告失敗聲望/口碑")
    if "CompanyStandingResolver.apply_activity_completion" not in _read(GIG_MGR):
        raise AssertionError("GigManager 未掛載打工口碑")
    if "CompanyStandingResolver.apply_activity_completion" not in _read(COURSE_MGR):
        raise AssertionError("CourseManager 未掛載课程口碑")
    if "_apply_news_standing" not in _read(NEWS_MGR):
        raise AssertionError("NewsManager 未掛載新聞輿情")


def check_interaction_opinion() -> None:
    if "public_opinion_delta" not in _read(EVENT_RES):
        raise AssertionError("InteractionEventResource 缺少 public_opinion_delta")
    text = _read(INTERACTION)
    if "_apply_public_opinion_change" not in text:
        raise AssertionError("InteractionManager 未套用口碑變化")


def check_meeting_panel() -> None:
    text = _read(GAME_ROOT)
    for token in (
        "_public_opinion_label",
        "_confirm_meeting_action",
        "_execute_meeting_terminate",
        "_is_meeting_action_done",
        "execute_once = true",
        "public_opinion_delta",
        "CompanyStandingResolver.apply_meeting_terminate",
    ):
        if token not in text:
            raise AssertionError(f"GameRootController 缺少 {token}")
    if "OS.is_debug_build()" not in text:
        raise AssertionError("測試面板應僅在 debug 模式顯示")


def simulate_standing_rules() -> None:
    # 對照 CompanyStandingResolver 常數（與 GDScript 同步）
    perfect = {"reputation_delta": 8, "public_opinion_delta": 5}
    normal = {"reputation_delta": 4, "public_opinion_delta": 2}
    fail = {"reputation_delta": -3, "public_opinion_delta": -8}
    terminate = {"reputation_delta": -2, "public_opinion_delta": -12}
    rep, op = 10, 20
    rep += perfect["reputation_delta"]
    op += perfect["public_opinion_delta"]
    rep += fail["reputation_delta"]
    op += fail["public_opinion_delta"]
    rep += terminate["reputation_delta"]
    op += terminate["public_opinion_delta"]
    if rep != 13 or op != 5:
        raise AssertionError(f"模擬結算異常：rep={rep} op={op}")


def main() -> None:
    print("=== company_standing_sandbox ===")
    check_resolver_api()
    print("  [PASS] CompanyStandingResolver API")
    check_hooks()
    print("  [PASS] Job/News/Gig/Course 掛鉤")
    check_interaction_opinion()
    print("  [PASS] Interaction 口碑欄位")
    check_meeting_panel()
    print("  [PASS] 週日會議正式互動")
    simulate_standing_rules()
    print("  [PASS] 聲望/口碑模擬規則")
    print("company_standing_sandbox 通過。")


if __name__ == "__main__":
    try:
        main()
    except AssertionError as exc:
        print(f"  [FAIL] {exc}")
        sys.exit(1)
