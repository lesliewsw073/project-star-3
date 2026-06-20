#!/usr/bin/env python3
"""度假整週 + 單日覆蓋沙盘（5 轮）。"""

from __future__ import annotations

DAYS = 7

# ScheduleType（与 ScheduleManager.gd 一致）
WORK_OVERSEAS = 1
GIG = 6
ROUTINE_EMPTY = 10
VACATION_DOMESTIC = 11
VACATION_OVERSEAS = 12

LOCK_UNLOCKED = 0
LOCKED_WEEK = 1
LOCKED_HARD = 2


def make_empty_slot() -> dict:
    return {"type": ROUTINE_EMPTY, "task_data": None, "lock_state": LOCK_UNLOCKED}


def make_week() -> list[dict]:
    return [make_empty_slot() for _ in range(DAYS)]


def is_vacation_type(schedule_type: int) -> bool:
    return schedule_type in (VACATION_DOMESTIC, VACATION_OVERSEAS)


def partial_override_allowed(slot: dict) -> bool:
    schedule_type = int(slot.get("type", ROUTINE_EMPTY))
    return is_vacation_type(schedule_type) or schedule_type == WORK_OVERSEAS


def set_whole_week(week: list[dict], schedule_type: int, task_data: str) -> bool:
    for slot in week:
        if int(slot.get("lock_state", LOCK_UNLOCKED)) == LOCKED_HARD:
            return False
    for slot in week:
        slot["type"] = schedule_type
        slot["task_data"] = task_data
        slot["lock_state"] = LOCKED_WEEK
    return True


def is_editable(week: list[dict], day_index: int) -> bool:
    lock = int(week[day_index].get("lock_state", LOCK_UNLOCKED))
    if lock == LOCK_UNLOCKED:
        return True
    if lock == LOCKED_WEEK:
        return partial_override_allowed(week[day_index])
    return False


def set_single_day(week: list[dict], day_index: int, schedule_type: int, task_data: str | None) -> bool:
    slot = week[day_index]
    lock = int(slot.get("lock_state", LOCK_UNLOCKED))
    if lock == LOCKED_HARD:
        return False
    if lock == LOCKED_WEEK:
        if not partial_override_allowed(slot):
            return False
        for i in range(DAYS):
            if i == day_index:
                continue
            if int(week[i].get("lock_state", LOCK_UNLOCKED)) == LOCKED_WEEK:
                week[i] = make_empty_slot()
        slot["type"] = schedule_type
        slot["task_data"] = task_data
        slot["lock_state"] = LOCK_UNLOCKED
        return True
    slot["type"] = schedule_type
    slot["task_data"] = task_data
    return True


def count_vacation_days(week: list[dict], vacation_id: str) -> int:
    n = 0
    for slot in week:
        if is_vacation_type(int(slot["type"])) and slot.get("task_data") == vacation_id:
            n += 1
    return n


def run_rounds() -> None:
    print("=== 度假整週沙盘（5 轮）===\n")
    passed = 0

    # 1. 度假覆盖整周
    week = make_week()
    assert set_whole_week(week, VACATION_DOMESTIC, "vac_hainan")
    assert count_vacation_days(week, "vac_hainan") == 7
    assert all(int(s["lock_state"]) == LOCKED_WEEK for s in week)
    print("第 1 轮：PASS：度假覆盖 7 天且整周锁定")
    passed += 1

    # 2. 单日打工覆盖，其余整周锁定格清空为空白
    week = make_week()
    set_whole_week(week, VACATION_DOMESTIC, "vac_hainan")
    assert is_editable(week, 3)
    assert set_single_day(week, 3, GIG, "gig_bar_singer_01")
    assert week[3]["type"] == GIG and week[3]["task_data"] == "gig_bar_singer_01"
    assert count_vacation_days(week, "vac_hainan") == 0
    for i in [0, 1, 2, 4, 5, 6]:
        assert week[i]["type"] == ROUTINE_EMPTY
    print("第 2 轮：PASS：单日打工覆盖后其余日期变为空白")
    passed += 1

    # 3. 单日通告覆盖
    week = make_week()
    set_whole_week(week, VACATION_OVERSEAS, "vac_paris")
    assert set_single_day(week, 1, 0, "job_inst_01")  # WORK_LOCAL=0
    assert week[1]["type"] == 0 and week[1]["task_data"] == "job_inst_01"
    assert count_vacation_days(week, "vac_paris") == 0
    assert week[0]["type"] == ROUTINE_EMPTY and week[2]["type"] == ROUTINE_EMPTY
    print("第 3 轮：PASS：单日通告覆盖后其余变为空白")
    passed += 1

    # 4. 再选度假应重新覆盖整周
    week = make_week()
    set_whole_week(week, VACATION_DOMESTIC, "vac_a")
    set_single_day(week, 2, GIG, "gig_01")
    set_whole_week(week, VACATION_DOMESTIC, "vac_b")
    assert count_vacation_days(week, "vac_b") == 7
    assert week[2]["type"] == VACATION_DOMESTIC
    print("第 4 轮：PASS：再次选度假可整周覆盖含先前单日变更")
    passed += 1

    # 5. LOCKED_HARD 不可覆盖
    week = make_week()
    week[4]["lock_state"] = LOCKED_HARD
    week[4]["type"] = GIG
    week[4]["task_data"] = "gig_locked"
    assert not set_whole_week(week, VACATION_DOMESTIC, "vac_x")
    assert not set_single_day(week, 4, ROUTINE_EMPTY, None)
    print("第 5 轮：PASS：强制锁定格不可被度假或空白覆盖")
    passed += 1

    print(f"\n全部 {passed} 轮通过。")


if __name__ == "__main__":
    run_rounds()
