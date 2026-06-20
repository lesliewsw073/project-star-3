#!/usr/bin/env python3
"""
FollowPlanManager 逻辑沙盘 — 5 轮（纯 Python）。
验证：can_follow/get_signature 无互递归、双艺人跟随时合并/互斥、sanitize、压力测试。
"""

from __future__ import annotations

import copy
import sys
from dataclasses import dataclass, field
from typing import Any

# ScheduleType 占位（与 ScheduleManager 一致）
ROUTINE_EMPTY = 0
ROUTINE_REST = 3
ROUTINE_CREATION = 4
GIG = 6
COURSE = 5
WORK_LOCAL = 1
VACATION_DOMESTIC = 8

MAX_RECURSION_DEPTH = 256


@dataclass
class FollowState:
    signed_ids: list[str] = field(default_factory=list)
    draft_schedules: dict[str, list[dict]] = field(default_factory=dict)
    draft_follows: dict[str, list[bool]] = field(default_factory=dict)
    emit_count: int = 0
    _is_mutating: bool = False
    _call_depth: int = 0


def _ensure_week(store: dict[str, list[bool]], artist_id: str) -> list[bool]:
    if artist_id not in store:
        store[artist_id] = [False] * 7
    return store[artist_id]


def _ensure_schedule(state: FollowState, artist_id: str) -> list[dict]:
    if artist_id not in state.draft_schedules:
        state.draft_schedules[artist_id] = [{"type": ROUTINE_EMPTY, "task_data": None}] * 7
    return state.draft_schedules[artist_id]


def get_slot_task_signature(slot: dict) -> str:
    """镜像 FollowPlanManager.get_slot_task_signature — 绝不可调用 can_follow_slot。"""
    schedule_type = int(slot.get("type", ROUTINE_EMPTY))
    task_data = slot.get("task_data")
    if schedule_type in (WORK_LOCAL,) and isinstance(task_data, dict) and task_data.get("kind") == "job":
        return "job:%s" % task_data["id"]
    if schedule_type == GIG and isinstance(task_data, str):
        return "gig:%s" % task_data
    if schedule_type == COURSE and isinstance(task_data, str):
        return "course:%s" % task_data
    return ""


def can_follow_slot(slot: dict) -> bool:
    schedule_type = int(slot.get("type", ROUTINE_EMPTY))
    if schedule_type in (ROUTINE_REST, ROUTINE_EMPTY, ROUTINE_CREATION, VACATION_DOMESTIC):
        return False
    if schedule_type in (GIG, COURSE, WORK_LOCAL):
        return get_slot_task_signature(slot) != ""
    return False


def _track_depth(fn):
    def wrapper(state: FollowState, *args, **kwargs):
        state._call_depth += 1
        if state._call_depth > MAX_RECURSION_DEPTH:
            raise RecursionError("call depth exceeded — possible infinite recursion")
        try:
            return fn(state, *args, **kwargs)
        finally:
            state._call_depth -= 1
    return wrapper


@_track_depth
def set_follow_enabled(state: FollowState, artist_id: str, day_index: int, enabled: bool) -> bool:
    if state._is_mutating:
        return False
    if artist_id not in state.signed_ids or not (0 <= day_index < 7):
        return False

    week = _ensure_schedule(state, artist_id)
    slot = week[day_index]
    if enabled and not can_follow_slot(slot):
        return False

    state._is_mutating = True
    store = state.draft_follows
    try:
        if enabled:
            signature = get_slot_task_signature(slot)
            if signature == "":
                return False
            for aid in state.signed_ids:
                _ensure_week(store, aid)
                other_slot = _ensure_schedule(state, aid)[day_index]
                store[aid][day_index] = (
                    get_slot_task_signature(other_slot) == signature and can_follow_slot(other_slot)
                )
        else:
            _ensure_week(store, artist_id)
            signature = get_slot_task_signature(slot)
            if signature == "":
                store[artist_id][day_index] = False
            else:
                for aid in state.signed_ids:
                    _ensure_week(store, aid)
                    other_slot = _ensure_schedule(state, aid)[day_index]
                    if get_slot_task_signature(other_slot) == signature:
                        store[aid][day_index] = False
        sanitize_draft_follows(state)
    finally:
        state._is_mutating = False

    state.emit_count += 1
    return True


def sanitize_draft_follows(state: FollowState) -> None:
    for artist_id in state.signed_ids:
        _ensure_week(state.draft_follows, artist_id)
        for day_index in range(7):
            if not state.draft_follows[artist_id][day_index]:
                continue
            slot = _ensure_schedule(state, artist_id)[day_index]
            if not can_follow_slot(slot):
                state.draft_follows[artist_id][day_index] = False


def sign_artist(state: FollowState, artist_id: str) -> None:
    if artist_id not in state.signed_ids:
        state.signed_ids.append(artist_id)
    _ensure_week(state.draft_follows, artist_id)
    _ensure_schedule(state, artist_id)


def set_slot(state: FollowState, artist_id: str, day_index: int, schedule_type: int, task_data: Any) -> None:
    _ensure_schedule(state, artist_id)[day_index] = {"type": schedule_type, "task_data": task_data}


def round1_no_recursion_on_signature_chain() -> str:
    slot = {"type": GIG, "task_data": "gig_bar_singer_01"}
    state = FollowState()
    for _ in range(5000):
        assert can_follow_slot(slot)
        assert get_slot_task_signature(slot) == "gig:gig_bar_singer_01"
    rest = {"type": ROUTINE_REST, "task_data": None}
    assert not can_follow_slot(rest)
    assert get_slot_task_signature(rest) == ""
    return "PASS：can_follow ↔ get_signature 5000 次无递归"


def round2_second_artist_same_gig_merge() -> str:
    state = FollowState()
    sign_artist(state, "artist_001")
    sign_artist(state, "artist_002")
    set_slot(state, "artist_001", 2, GIG, "gig_bar_singer_01")
    set_slot(state, "artist_002", 2, GIG, "gig_bar_singer_01")
    assert set_follow_enabled(state, "artist_001", 2, True)
    assert state.draft_follows["artist_001"][2]
    assert state.draft_follows["artist_002"][2]
    return "PASS：签第二艺人 + 同日同打工 → 跟随自动合并"


def round3_exclusive_follow_different_tasks() -> str:
    state = FollowState()
    sign_artist(state, "artist_001")
    sign_artist(state, "artist_002")
    set_slot(state, "artist_001", 1, GIG, "gig_bar_singer_01")
    set_slot(state, "artist_002", 1, COURSE, "course_acting_basic_01")
    assert set_follow_enabled(state, "artist_001", 1, True)
    assert state.draft_follows["artist_001"][1]
    assert not state.draft_follows["artist_002"][1]
    assert set_follow_enabled(state, "artist_002", 1, True)
    assert state.draft_follows["artist_002"][1]
    assert not state.draft_follows["artist_001"][1]
    return "PASS：不同任务跟随互斥，后者覆盖前者"


def round4_sanitize_clears_invalid_follow() -> str:
    state = FollowState()
    sign_artist(state, "artist_001")
    set_slot(state, "artist_001", 0, GIG, "gig_bar_singer_01")
    set_follow_enabled(state, "artist_001", 0, True)
    set_slot(state, "artist_001", 0, ROUTINE_REST, None)
    sanitize_draft_follows(state)
    assert not state.draft_follows["artist_001"][0]
    return "PASS：行程改为休息后 sanitize 清除跟随"


def round5_stress_multi_artist_no_overflow() -> str:
    state = FollowState()
    for i in range(1, 5):
        aid = "artist_%03d" % i
        sign_artist(state, aid)
        set_slot(state, aid, 3, GIG if i % 2 else COURSE, "gig_bar_singer_01" if i % 2 else "course_acting_basic_01")
    for _ in range(200):
        for aid in state.signed_ids:
            set_follow_enabled(state, aid, 3, True)
            set_follow_enabled(state, aid, 3, False)
        sanitize_draft_follows(state)
    assert state._call_depth == 0
    assert state.emit_count == 200 * len(state.signed_ids) * 2
    return "PASS：4 艺人 × 200 轮 set_follow/sanitize，无栈溢出"


def main() -> None:
    rounds = [
        ("第 1 轮", round1_no_recursion_on_signature_chain),
        ("第 2 轮", round2_second_artist_same_gig_merge),
        ("第 3 轮", round3_exclusive_follow_different_tasks),
        ("第 4 轮", round4_sanitize_clears_invalid_follow),
        ("第 5 轮", round5_stress_multi_artist_no_overflow),
    ]
    print("=== FollowPlan 沙盘（5 轮）===\n")
    for title, fn in rounds:
        msg = fn()
        print(f"{title}：{msg}")
    print("\n全部 5 轮通过。")


if __name__ == "__main__":
    try:
        main()
    except RecursionError as exc:
        print(f"FAIL：{exc}", file=sys.stderr)
        sys.exit(1)
