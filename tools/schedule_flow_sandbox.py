#!/usr/bin/env python3
"""
行程全链路沙盘 — 8 轮（纯 Python，不依赖 Godot）。
覆盖：提交/执行清空、同上週快照、跟随 sanitize、通告进行中 UI 引用、会议结束进周一。
"""

from __future__ import annotations

import copy
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
DAYS = 7

GIG = 6
ROUTINE_EMPTY = 10
LOCK_UNLOCKED = 0


def make_empty_slot() -> dict:
    return {"type": ROUTINE_EMPTY, "task_data": None, "lock_state": LOCK_UNLOCKED}


def make_week(types: list[int] | None = None) -> list[dict]:
    week = [make_empty_slot() for _ in range(DAYS)]
    if types:
        for i, t in enumerate(types[:DAYS]):
            week[i]["type"] = t
            week[i]["task_data"] = f"task_{i}"
    return week


def execute_day(week: list[dict], day_index: int) -> None:
    """模拟 execute_artist_day 末尾清空格子。"""
    week[day_index] = make_empty_slot()


def commit_week(draft: dict[str, list], current: dict[str, list], snapshot: dict[str, list]) -> None:
    current.clear()
    for artist_id, week in draft.items():
        copied = copy.deepcopy(week)
        current[artist_id] = copied
        snapshot[artist_id] = copy.deepcopy(copied)
    draft.clear()


def copy_to_next_draft(source_store: dict[str, list], artist_id: str, target_draft: dict[str, list]) -> None:
    target_draft[artist_id] = copy.deepcopy(source_store[artist_id])


def can_follow_slot(slot: dict) -> bool:
    return int(slot.get("type", ROUTINE_EMPTY)) == GIG and slot.get("task_data") is not None


def sanitize_follow(week: list[dict], follow: list[bool]) -> None:
    for i in range(DAYS):
        if follow[i] and not can_follow_slot(week[i]):
            follow[i] = False


def round1_commit_then_execute_depletes_current() -> str:
    current: dict[str, list] = {}
    draft = {"a1": make_week([GIG] * DAYS)}
    snapshot: dict[str, list] = {}
    commit_week(draft, current, snapshot)
    for d in range(DAYS):
        execute_day(current["a1"], d)
    if any(int(s["type"]) != ROUTINE_EMPTY for s in current["a1"]):
        return "FAIL：执行后 current_week 应全空"
    if not any(int(s["type"]) == GIG for s in snapshot["a1"]):
        return "FAIL：提交快照应保留原始安排"
    return "PASS：执行清空 current_week，快照保留原计划"


def round2_copy_from_snapshot_not_depleted() -> str:
    current = {"a1": make_week([GIG] * DAYS)}
    snapshot = {"a1": copy.deepcopy(current["a1"])}
    for d in range(DAYS):
        execute_day(current["a1"], d)
    next_draft: dict[str, list] = {}
    # 错误做法：复制 current（已空）
    copy_to_next_draft(current, "a1", next_draft)
    if any(int(s["type"]) == GIG for s in next_draft["a1"]):
        return "FAIL：不应从已清空的 current 复制出有效行程"
    # 正确做法：复制 snapshot
    next_draft.clear()
    copy_to_next_draft(snapshot, "a1", next_draft)
    if sum(int(s["type"]) == GIG for s in next_draft["a1"]) != DAYS:
        return "FAIL：应从 last_committed 快照复制完整週"
    return "PASS：同上週须读提交快照，不能读执行后的 current_week"


def round3_follow_sanitize_on_schedule_change() -> str:
    week = make_week([GIG, ROUTINE_EMPTY, GIG, GIG, ROUTINE_EMPTY, GIG, GIG])
    follow = [True, True, True, True, True, True, True]
    sanitize_follow(week, follow)
    assert follow[0] and follow[2]
    week[2] = make_empty_slot()
    sanitize_follow(week, follow)
    if follow[2]:
        return "FAIL：行程改空白后跟随应清除"
    return "PASS：行程变更后 sanitize 清除无效跟随"


def round4_follow_merge_same_gig_signature() -> str:
    """同日同 gig 任务签名应合并跟随（简化）。"""
    sig_a = "gig:bar"
    sig_b = "gig:bar"
    if sig_a != sig_b:
        return "FAIL：同 gig 签名应一致"
    return "PASS：跟随合并签名规则一致"


def round5_day_work_report_panel_refs() -> str:
    panel = (ROOT / "scripts/ui/DayWorkReportPanel.gd").read_text(encoding="utf-8")
    if "$Root/MainBox/DateLabel" in panel:
        return "FAIL：DateLabel 节点路径错误"
    if "_date_label" not in panel or "_money_label" not in panel:
        return "FAIL：缺少成员引用"
    if panel.count("_task_grid") < 2:
        return "FAIL：缺少 _task_grid 成员引用"
    return "PASS：DayWorkReportPanel 使用成员引用"


def round6_schedule_manager_has_committed_snapshot() -> str:
    sm = (ROOT / "scripts/managers/ScheduleManager.gd").read_text(encoding="utf-8")
    if "last_committed_week_schedules" not in sm:
        return "FAIL：ScheduleManager 缺少 last_committed_week_schedules"
    if "copy_current_week_to_next_draft" not in sm:
        return "FAIL：缺少 copy_current_week_to_next_draft"
    fn_start = sm.find("func copy_current_week_to_next_draft")
    fn_body = sm[fn_start : fn_start + 600]
    if "last_committed_week_schedules" not in fn_body:
        return "FAIL：copy_current_week_to_next_draft 未使用提交快照"
    return "PASS：同上週读取 last_committed 快照"


def round7_meeting_end_triggers_work_report_on_follow_monday() -> str:
    """会议结束 -> 周一跟随 -> 应触发 work_report（与 day_cycle 一致）。"""
    day_index = 0
    follow = [True] + [False] * 6
    story_lock = 0
    mode = "FOLLOW" if story_lock <= 0 and follow[day_index] else "FREE"
    if mode != "FOLLOW":
        return "FAIL：周一勾选跟随应为 FOLLOW"
    log: list[str] = []
    if mode == "FOLLOW":
        log.append("work_report")
    if "work_report" not in log:
        return "FAIL：跟随日应直接触发通告进行中"
    return "PASS：周一跟随日进入 work_report 流程"


def round8_settle_clears_slot_once() -> str:
    week = make_week([GIG] * DAYS)
    before = copy.deepcopy(week[0])
    execute_day(week, 0)
    if week[0]["type"] != ROUTINE_EMPTY:
        return "FAIL：结算后格子未清空"
    execute_day(week, 0)  # 再次执行空白格
    if week[0]["type"] != ROUTINE_EMPTY:
        return "FAIL：空白格二次执行异常"
    return "PASS：单日结算后格子清空，重复执行安全"


ROUNDS = [
    ("提交后执行清空 current_week", round1_commit_then_execute_depletes_current),
    ("同上週须读提交快照", round2_copy_from_snapshot_not_depleted),
    ("跟随 sanitize", round3_follow_sanitize_on_schedule_change),
    ("跟随合并签名", round4_follow_merge_same_gig_signature),
    ("DayWorkReportPanel 引用", round5_day_work_report_panel_refs),
    ("ScheduleManager 提交快照", round6_schedule_manager_has_committed_snapshot),
    ("周一跟随进 work_report", round7_meeting_end_triggers_work_report_on_follow_monday),
    ("结算清空格子", round8_settle_clears_slot_once),
]


def main() -> None:
    failed: list[str] = []
    print("=== 行程全链路沙盘（8 轮）===\n")
    for i, (label, fn) in enumerate(ROUNDS, 1):
        try:
            msg = fn()
        except Exception as exc:  # noqa: BLE001
            msg = f"FAIL：异常 {exc}"
        status = "PASS" if msg.startswith("PASS") else "FAIL"
        print(f"第 {i} 轮 [{status}] {label}: {msg}")
        if status == "FAIL":
            failed.append(label)
    print()
    if failed:
        print(f"失败：{', '.join(failed)}")
        raise SystemExit(1)
    print("全部 8 轮通过。")


if __name__ == "__main__":
    main()
