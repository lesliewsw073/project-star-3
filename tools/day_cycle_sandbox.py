#!/usr/bin/env python3
"""
日循环三分支沙盘 — 5 轮（纯 Python，不依赖 Godot）。
验证：DayMode 优先级、跟随锁地图、自由探索进出地图、剧情锁递减、状态往返。
"""

from __future__ import annotations

import copy
import json
from dataclasses import dataclass, field
from typing import Any

GAME_PHASE_DAY = "DAY_OPERATION"
GAME_PHASE_MEETING = "WEEKLY_MEETING"

DAY_MODE_STORY_LOCK = 0
DAY_MODE_FOLLOW = 1
DAY_MODE_FREE = 2


@dataclass
class FlowState:
    game_phase: str = GAME_PHASE_DAY
    day_index: int = 0
    story_lock_days_remaining: int = 0
    story_lock_event_id: str = ""
    is_exploring_map: bool = False
    day_settlement_done: bool = False
    work_report_dismissed: bool = False
    story_playback_active: bool = False
    follow_plan: dict[str, list[bool]] = field(default_factory=dict)
    log: list[str] = field(default_factory=list)


def _ensure_week(plan: dict[str, list[bool]], artist_id: str) -> list[bool]:
    if artist_id not in plan:
        plan[artist_id] = [False] * 7
    return plan[artist_id]


def has_follow_today(state: FlowState) -> bool:
    for week in state.follow_plan.values():
        if day_index_in_bounds(state.day_index) and week[state.day_index]:
            return True
    return False


def day_index_in_bounds(day_index: int) -> bool:
    return 0 <= day_index < 7


def get_day_mode(state: FlowState) -> int:
    if state.game_phase != GAME_PHASE_DAY:
        return -1
    if state.story_lock_days_remaining > 0:
        return DAY_MODE_STORY_LOCK
    if has_follow_today(state):
        return DAY_MODE_FOLLOW
    return DAY_MODE_FREE


def can_enter_map(state: FlowState) -> bool:
    return (
        state.game_phase == GAME_PHASE_DAY
        and get_day_mode(state) == DAY_MODE_FREE
        and not state.is_exploring_map
    )


def enter_map(state: FlowState) -> dict[str, Any]:
    if not can_enter_map(state):
        return {"success": False, "reason": "blocked"}
    state.is_exploring_map = True
    state.log.append("enter_map")
    return {"success": True}


def exit_map(state: FlowState) -> dict[str, Any]:
    if not state.is_exploring_map:
        return {"success": False, "reason": "not_on_map"}
    state.is_exploring_map = False
    state.log.append("exit_map")
    if get_day_mode(state) == DAY_MODE_FREE and not state.day_settlement_done:
        trigger_work_report(state)
    return {"success": True}


def can_finish_today(state: FlowState) -> bool:
    if state.game_phase != GAME_PHASE_DAY:
        return False
    mode = get_day_mode(state)
    if mode == DAY_MODE_STORY_LOCK:
        return state.story_lock_days_remaining > 0
    if mode == DAY_MODE_FREE:
        return not state.day_settlement_done
    if mode == DAY_MODE_FOLLOW:
        return (
            state.day_settlement_done
            and state.work_report_dismissed
            and not state.story_playback_active
        )
    return False


def finish_today(state: FlowState) -> None:
    if not can_finish_today(state):
        return
    mode = get_day_mode(state)
    if mode == DAY_MODE_STORY_LOCK:
        end_day(state)
    elif mode == DAY_MODE_FREE:
        if state.is_exploring_map:
            exit_map(state)
        else:
            trigger_work_report(state)
    elif mode == DAY_MODE_FOLLOW:
        state.log.append("notify_follow_stories_finished")
        finish_day_and_advance(state)


def trigger_work_report(state: FlowState) -> None:
    state.log.append(f"work_report:{get_day_mode(state)}")
    state.day_settlement_done = True
    state.work_report_dismissed = False
    state.work_report_dismissed = False


def dismiss_work_report(state: FlowState) -> None:
    if not state.day_settlement_done:
        return
    state.work_report_dismissed = True
    mode = get_day_mode(state)
    if mode == DAY_MODE_FOLLOW:
        state.log.append("follow_day_finished")
    else:
        finish_day_and_advance(state)


def begin_operational_day(state: FlowState) -> None:
    if state.game_phase != GAME_PHASE_DAY:
        return
    state.day_settlement_done = False
    state.work_report_dismissed = False
    mode = get_day_mode(state)
    if mode == DAY_MODE_FOLLOW:
        trigger_work_report(state)
    elif mode == DAY_MODE_FREE:
        enter_map(state)


def finish_day_and_advance(state: FlowState) -> None:
    state.day_index = (state.day_index + 1) % 7
    if state.day_index == 0:
        state.game_phase = GAME_PHASE_MEETING
        state.day_settlement_done = False
        return
    state.day_settlement_done = False
    begin_operational_day(state)


def start_story_lock(state: FlowState, days: int, event_id: str = "") -> None:
    if days <= 0:
        return
    if state.is_exploring_map:
        state.is_exploring_map = False
        state.log.append("force_exit_map_for_story_lock")
    state.story_lock_days_remaining = days
    state.story_lock_event_id = event_id
    state.log.append(f"story_lock_start:{event_id}:{days}")


def end_day(state: FlowState) -> None:
    if get_day_mode(state) != DAY_MODE_STORY_LOCK:
        return
    if state.is_exploring_map:
        state.is_exploring_map = False
        state.log.append("exit_map")

    state.log.append(f"settle:{DAY_MODE_STORY_LOCK}")
    if state.story_lock_days_remaining > 0:
        state.story_lock_days_remaining -= 1
        if state.story_lock_days_remaining <= 0:
            state.log.append(f"story_lock_finished:{state.story_lock_event_id}")
            state.story_lock_event_id = ""
    finish_day_and_advance(state)


def export_flow(state: FlowState) -> dict[str, Any]:
    return {
        "game_phase": state.game_phase,
        "day_index": state.day_index,
        "story_lock_days_remaining": state.story_lock_days_remaining,
        "story_lock_event_id": state.story_lock_event_id,
        "is_exploring_map": state.is_exploring_map,
        "follow_plan": copy.deepcopy(state.follow_plan),
    }


def import_flow(payload: dict[str, Any]) -> FlowState:
    state = FlowState(
        game_phase=str(payload.get("game_phase", GAME_PHASE_DAY)),
        day_index=int(payload.get("day_index", 0)),
        story_lock_days_remaining=int(payload.get("story_lock_days_remaining", 0)),
        story_lock_event_id=str(payload.get("story_lock_event_id", "")),
        is_exploring_map=bool(payload.get("is_exploring_map", False)),
        follow_plan=copy.deepcopy(payload.get("follow_plan", {})),
    )
    return state


def round1_day_mode_priority() -> str:
    state = FlowState()
    assert get_day_mode(state) == DAY_MODE_FREE

    _ensure_week(state.follow_plan, "artist_001")[0] = True
    assert get_day_mode(state) == DAY_MODE_FOLLOW

    start_story_lock(state, 2, "main_story_01")
    assert get_day_mode(state) == DAY_MODE_STORY_LOCK
    assert not can_enter_map(state)
    return "PASS：DayMode 优先级 = 剧情锁 > 跟随 > 自由"


def round2_follow_blocks_map() -> str:
    state = FlowState(day_index=2)
    _ensure_week(state.follow_plan, "artist_001")[2] = True
    assert get_day_mode(state) == DAY_MODE_FOLLOW
    assert not can_enter_map(state)
    blocked = enter_map(state)
    assert blocked["success"] is False
    begin_operational_day(state)
    assert "work_report:1" in state.log
    dismiss_work_report(state)
    assert "follow_day_finished" in state.log
    return "PASS：跟随日不可进地图；work_report 後触发 follow_day_finished"


def round3_free_explore_map() -> str:
    state = FlowState(day_index=1)
    begin_operational_day(state)
    assert state.is_exploring_map is True
    assert not can_enter_map(state)
    assert exit_map(state)["success"] is True
    assert "work_report:2" in state.log
    assert state.is_exploring_map is False
    dismiss_work_report(state)
    assert state.day_index == 2
    return "PASS：自由探索日自动进地图；离图后 work_report 并推进日期"


def round4_story_lock_countdown() -> str:
    state = FlowState(day_index=4)
    start_story_lock(state, 2, "locked_arc")
    assert get_day_mode(state) == DAY_MODE_STORY_LOCK
    end_day(state)
    assert state.story_lock_days_remaining == 1
    assert get_day_mode(state) == DAY_MODE_STORY_LOCK
    end_day(state)
    assert state.story_lock_days_remaining == 0
    assert get_day_mode(state) == DAY_MODE_FREE
    assert "story_lock_finished:locked_arc" in state.log
    return "PASS：剧情锁按 end_day 递减，结束后恢复 FREE"


def round5_export_import_roundtrip() -> str:
    state = FlowState(day_index=3)
    week = _ensure_week(state.follow_plan, "artist_002")
    week[3] = True
    week[4] = True
    start_story_lock(state, 1, "save_test")
    state.is_exploring_map = False
    raw = json.dumps(export_flow(state), ensure_ascii=False)
    loaded = import_flow(json.loads(raw))
    assert loaded.day_index == 3
    assert loaded.story_lock_days_remaining == 1
    assert loaded.follow_plan["artist_002"][4] is True
    assert get_day_mode(loaded) == DAY_MODE_STORY_LOCK
    end_day(loaded)
    assert loaded.story_lock_days_remaining == 0
    assert loaded.day_index == 4
    assert get_day_mode(loaded) == DAY_MODE_FOLLOW
    assert "work_report:1" in loaded.log
    return "PASS：flow + follow_plan JSON 往返；剧情锁结束後進入下一日 FOLLOW"


def round6_finish_today_free_and_follow() -> str:
    state = FlowState(day_index=1)
    assert can_finish_today(state) is True
    state.is_exploring_map = False
    finish_today(state)
    assert "work_report:2" in state.log
    assert can_finish_today(state) is False

    state2 = FlowState(day_index=2)
    _ensure_week(state2.follow_plan, "artist_001")[2] = True
    begin_operational_day(state2)
    assert can_finish_today(state2) is False
    dismiss_work_report(state2)
    assert can_finish_today(state2) is True
    finish_today(state2)
    assert "notify_follow_stories_finished" in state2.log
    assert state2.day_index == 3
    return "PASS：can_finish_today — FREE 未結算可 finish；FOLLOW 日報關閉後可 finish"


def main() -> None:
    rounds = [
        ("第 1 轮", round1_day_mode_priority),
        ("第 2 轮", round2_follow_blocks_map),
        ("第 3 轮", round3_free_explore_map),
        ("第 4 轮", round4_story_lock_countdown),
        ("第 5 轮", round5_export_import_roundtrip),
        ("第 6 轮", round6_finish_today_free_and_follow),
    ]
    print("=== 日循环三分支沙盘（6 轮）===\n")
    for title, fn in rounds:
        msg = fn()
        print(f"{title}：{msg}")
    print("\n全部 6 轮通过。")


if __name__ == "__main__":
    main()
