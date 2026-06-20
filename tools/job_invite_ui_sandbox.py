#!/usr/bin/env python3
"""製片人邀請接案 UI 與 JobManager 輔助 API 接線檢查。"""

from __future__ import annotations

import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
JOB_RES = ROOT / "scripts/resources/JobResource.gd"
JOB_MGR = ROOT / "scripts/autoload/JobManager.gd"
JOB_INSTANCE = ROOT / "scripts/JobInstance.gd"
JOB_EVAL = ROOT / "scripts/managers/JobDayEvaluator.gd"
GAME_ROOT = ROOT / "scripts/controllers/GameRootController.gd"
MOVIE_JOB = ROOT / "data/jobs/test/test_job_movie_short_01.tres"

INVITE_W_REPUTATION = 0.4
INVITE_W_OPINION = 0.3
INVITE_W_FAME = 0.15
INVITE_W_POPULARITY = 0.10
INVITE_W_WORKS = 0.05
DEFAULT_INVITE_THRESHOLD = 300


def _read(path: Path) -> str:
    return path.read_text(encoding="utf-8")


def calculate_invite_score(
    reputation: int,
    opinion: int,
    fame: int,
    popularity: int,
    works: int,
) -> float:
    return (
        reputation * INVITE_W_REPUTATION
        + opinion * INVITE_W_OPINION
        + fame * INVITE_W_FAME
        + popularity * INVITE_W_POPULARITY
        + works * INVITE_W_WORKS
    )


def check_job_resource_fields() -> None:
    text = _read(JOB_RES)
    for field in ("invite_only", "invite_threshold"):
        if f"var {field}" not in text:
            raise AssertionError(f"JobResource 缺少 {field}")


def check_job_manager_api() -> None:
    text = _read(JOB_MGR)
    for fn in (
        "try_accept_job_invite",
        "get_invite_threshold_for_job",
        "get_invite_block_reason",
        "build_invite_detail_text",
    ):
        if f"func {fn}" not in text:
            raise AssertionError(f"JobManager 缺少 {fn}")
    if "invite_only" not in text:
        raise AssertionError("JobManager._make_job_summary 未輸出 invite_only")
    if "此通告僅接受製片人邀請接案" not in text:
        raise AssertionError("get_accept_block_reason 未阻擋 invite_only 普通接案")


def check_job_instance_invite() -> None:
    text = _read(JOB_INSTANCE)
    if "try_accept_invite" not in text:
        raise AssertionError("JobInstance 缺少 try_accept_invite")
    if "ACCEPT_MODE_INVITE" not in text:
        raise AssertionError("JobInstance 邀請接案未寫入 ACCEPT_MODE_INVITE")


def check_game_root_ui() -> None:
    text = _read(GAME_ROOT)
    for token in (
        "_job_invite_accept_button",
        "_job_invite_detail_label",
        "_on_job_invite_accept_pressed",
        "_execute_job_invite_accept",
        "try_accept_job_invite",
        "build_invite_detail_text",
        "get_invite_block_reason",
        "接受製片人邀請",
        "【邀請】",
    ):
        if token not in text:
            raise AssertionError(f"GameRootController 缺少邀請接案 UI：{token}")


def check_invite_only_test_job() -> None:
    text = _read(MOVIE_JOB)
    if "invite_only = true" not in text:
        raise AssertionError("test_job_movie_short_01 未標記 invite_only")
    if "req_acting = 50" not in text:
        raise AssertionError("test_job_movie_short_01 門檻應提高以區分普通/邀請接案")


def check_invite_score_formula() -> None:
    text = _read(JOB_EVAL)
    if "DEFAULT_INVITE_THRESHOLD" not in text:
        raise AssertionError("JobDayEvaluator 缺少 DEFAULT_INVITE_THRESHOLD")
    score = calculate_invite_score(500, 400, 200, 150, 10)
    if score < DEFAULT_INVITE_THRESHOLD:
        raise AssertionError(f"高公司/藝人分數應達門檻，實際 {score}")
    low = calculate_invite_score(0, 0, 0, 0, 0)
    if low >= DEFAULT_INVITE_THRESHOLD:
        raise AssertionError("零分不應達邀請門檻")


def check_threshold_resolver() -> None:
    text = _read(JOB_MGR)
    match = re.search(
        r"func get_invite_threshold_for_job\(job: JobResource\) -> int:.*?return JobDayEvaluator\.DEFAULT_INVITE_THRESHOLD",
        text,
        re.S,
    )
    if match is None:
        raise AssertionError("get_invite_threshold_for_job 未回退至 DEFAULT_INVITE_THRESHOLD")


def main() -> None:
    check_job_resource_fields()
    check_job_manager_api()
    check_job_instance_invite()
    check_game_root_ui()
    check_invite_only_test_job()
    check_invite_score_formula()
    check_threshold_resolver()
    print("job_invite_ui_sandbox: 全部檢查通過。")


if __name__ == "__main__":
    try:
        main()
    except AssertionError as exc:
        print(f"job_invite_ui_sandbox: 失敗 — {exc}", file=sys.stderr)
        sys.exit(1)
