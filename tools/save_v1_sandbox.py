#!/usr/bin/env python3
"""
Save v1 骨架 — 5 轮沙盘模拟（纯 Python，不依赖 Godot）。
验证：DTO 往返、引用解析、边界条件、版本迁移钩子、库存占位。
"""

from __future__ import annotations

import copy
import json
from dataclasses import dataclass, field
from typing import Any

SAVE_VERSION = 1
MAX_AFFECTION = 100
DAYS_PER_WEEK = 7

# --- 占位：ScheduleType / LockState / task kind ---
SCHEDULE_EMPTY = 0
SCHEDULE_GIG = 6
SCHEDULE_COURSE = 5
SCHEDULE_JOB = 1
LOCK_UNLOCKED = 0


@dataclass
class JobInstanceState:
    instance_id: str
    job_id: str
    artist_id: str
    qualified_shoot_days: int = 0
    window_start_total_day: int = 10
    current_status: int = 4  # SHOOTING


@dataclass
class GameState:
    time: dict[str, int]
    flow: dict[str, bool]
    player: dict[str, Any]
    relationships: dict[str, int]
    roster: dict[str, dict[str, Any]]
    schedules_current: dict[str, list[dict]]
    schedules_draft: dict[str, list[dict]]
    active_jobs: dict[str, JobInstanceState]
    interaction_flags: dict[str, Any]
    executed_events: dict[str, bool]
    inventory: dict[str, int]
    next_job_serial: int = 1


def make_slot(schedule_type: int, kind: str | None, ref_id: str | None, lock: int = LOCK_UNLOCKED) -> dict:
    task_ref = None
    if kind and ref_id:
        task_ref = {"kind": kind, "id": ref_id}
    return {"type": schedule_type, "lock_state": lock, "task_ref": task_ref}


def export_state(state: GameState) -> dict:
    jobs_payload = []
    for inst in state.active_jobs.values():
        jobs_payload.append(
            {
                "instance_id": inst.instance_id,
                "job_id": inst.job_id,
                "artist_id": inst.artist_id,
                "qualified_shoot_days": inst.qualified_shoot_days,
                "window_start_total_day": inst.window_start_total_day,
                "current_status": inst.current_status,
            }
        )
    return {
        "save_version": SAVE_VERSION,
        "time": copy.deepcopy(state.time),
        "flow": copy.deepcopy(state.flow),
        "player": copy.deepcopy(state.player),
        "relationships": copy.deepcopy(state.relationships),
        "roster": copy.deepcopy(state.roster),
        "schedules": {
            "current_week": copy.deepcopy(state.schedules_current),
            "next_draft": copy.deepcopy(state.schedules_draft),
        },
        "jobs": {
            "next_instance_serial": state.next_job_serial,
            "active": jobs_payload,
        },
        "interaction": {
            "flags": copy.deepcopy(state.interaction_flags),
            "executed_event_ids": copy.deepcopy(state.executed_events),
        },
        "inventory": copy.deepcopy(state.inventory),
    }


def migrate_payload(payload: dict) -> dict:
    version = int(payload.get("save_version", 0))
    if version == 0:
        payload["save_version"] = 1
        payload.setdefault("inventory", {})
    if version > SAVE_VERSION:
        raise ValueError(f"存档版本过新: {version} > {SAVE_VERSION}")
    return payload


def resolve_task_ref(task_ref: dict | None, state: GameState) -> Any:
    if not task_ref:
        return None
    kind = task_ref.get("kind")
    ref_id = task_ref.get("id")
    if kind == "job_instance":
        return state.active_jobs.get(ref_id)
    if kind == "gig":
        return {"gig_id": ref_id}
    if kind == "course":
        return {"course_id": ref_id}
    return None


def import_state(payload: dict) -> GameState:
    payload = migrate_payload(payload)
    if payload["save_version"] != SAVE_VERSION:
        raise ValueError("unsupported version after migrate")

    state = GameState(
        time=dict(payload["time"]),
        flow=dict(payload["flow"]),
        player=dict(payload["player"]),
        relationships={k: int(v) for k, v in payload["relationships"].items()},
        roster=copy.deepcopy(payload["roster"]),
        schedules_current={},
        schedules_draft={},
        active_jobs={},
        interaction_flags=dict(payload["interaction"]["flags"]),
        executed_events={k: bool(v) for k, v in payload["interaction"]["executed_event_ids"].items()},
        inventory={k: int(v) for k, v in payload.get("inventory", {}).items()},
        next_job_serial=int(payload["jobs"].get("next_instance_serial", 1)),
    )

    for entry in payload["jobs"]["active"]:
        inst = JobInstanceState(
            instance_id=entry["instance_id"],
            job_id=entry["job_id"],
            artist_id=entry["artist_id"],
            qualified_shoot_days=int(entry.get("qualified_shoot_days", 0)),
            window_start_total_day=int(entry.get("window_start_total_day", 0)),
            current_status=int(entry.get("current_status", 0)),
        )
        state.active_jobs[inst.instance_id] = inst

    for artist_id, week in payload["schedules"]["current_week"].items():
        state.schedules_current[artist_id] = copy.deepcopy(week)
    for artist_id, week in payload["schedules"]["next_draft"].items():
        state.schedules_draft[artist_id] = copy.deepcopy(week)

    return state


def assert_roundtrip(state: GameState) -> None:
    raw = json.dumps(export_state(state), ensure_ascii=False)
    loaded = import_state(json.loads(raw))
    assert loaded.time == state.time
    assert loaded.player == state.player
    assert loaded.relationships == state.relationships
    assert loaded.roster == state.roster
    assert loaded.inventory == state.inventory
    assert len(loaded.active_jobs) == len(state.active_jobs)


def base_fixture() -> GameState:
    job = JobInstanceState(
        instance_id="test_job_tv_01_1",
        job_id="test_job_tv_01",
        artist_id="artist_001",
        qualified_shoot_days=2,
        window_start_total_day=15,
    )
    week = [
        make_slot(SCHEDULE_JOB, "job_instance", job.instance_id),
        make_slot(SCHEDULE_GIG, "gig", "gig_bar_singer_01"),
        make_slot(SCHEDULE_COURSE, "course", "course_acting_basic_01"),
    ] + [make_slot(SCHEDULE_EMPTY, None, None) for _ in range(4)]

    return GameState(
        time={"year": 1, "month": 2, "week": 3, "day_index": 4, "total_days_elapsed": 88},
        flow={"is_meeting_phase": True},
        player={
            "money": 120000,
            "company_scale": 0,
            "successful_jobs_count": 3,
            "perfect_jobs_count": 1,
        },
        relationships={"artist_001": 55, "secretary": 40},
        roster={
            "artist_001": {
                "fatigue": 30,
                "stress": 25,
                "satisfaction": 60,
                "acting": 12,
            }
        },
        schedules_current={"artist_001": copy.deepcopy(week)},
        schedules_draft={"artist_001": copy.deepcopy(week)},
        active_jobs={job.instance_id: job},
        interaction_flags={"intro_done": True},
        executed_events={"gift_secretary_once": True},
        inventory={"gift_chocolate_01": 2},
        next_job_serial=2,
    )


def round1_basic_roundtrip() -> str:
    state = base_fixture()
    assert_roundtrip(state)
    payload = export_state(state)
    assert payload["save_version"] == 1
    assert payload["time"]["total_days_elapsed"] == 88
    return "PASS：核心 DTO JSON 往返一致（time/player/roster/jobs/inventory）"


def round2_schedule_ref_resolve() -> str:
    state = import_state(export_state(base_fixture()))
    slot = state.schedules_current["artist_001"][0]
    resolved = resolve_task_ref(slot["task_ref"], state)
    assert resolved is not None
    assert resolved.instance_id == "test_job_tv_01_1"
    assert resolved.qualified_shoot_days == 2
    gig_slot = state.schedules_current["artist_001"][1]
    gig = resolve_task_ref(gig_slot["task_ref"], state)
    assert gig["gig_id"] == "gig_bar_singer_01"
    return "PASS：行程格 task_ref 可解析为 JobInstance / 静态模板 ID"


def round3_terminate_roster_schedule_orphan() -> str:
    state = base_fixture()
    # 解约：roster 清空，但 relationships 保留；行程应一并清或 load 时校验
    state.roster.pop("artist_001", None)
    state.schedules_current.pop("artist_001", None)
    state.schedules_draft.pop("artist_001", None)
    # active job 仍指向 artist_001 — load 规则应保留 job 或标记 orphan
    assert "artist_001" not in state.roster
    assert state.relationships["artist_001"] == 55
    reloaded = import_state(export_state(state))
    assert "artist_001" not in reloaded.roster
    assert reloaded.active_jobs["test_job_tv_01_1"].artist_id == "artist_001"
    return "PASS：解约后 roster/行程可剥离，好感保留；进行中通告需 load 时显式处理 orphan job"


def round4_version_migration_and_reject() -> str:
    state = base_fixture()
    payload = export_state(state)
    payload["save_version"] = 0
    payload.pop("inventory", None)
    loaded = import_state(payload)
    assert loaded.inventory == {}
    payload_new = export_state(base_fixture())
    payload_new["save_version"] = 99
    try:
        import_state(payload_new)
        raise AssertionError("应拒绝未来版本")
    except ValueError as e:
        assert "过新" in str(e)
    return "PASS：v0→v1 迁移补 inventory；未来版本拒绝加载"


def round5_inventory_and_flags_monotonic() -> str:
    state = base_fixture()
    state.inventory["gift_chocolate_01"] = 5
    state.executed_events["once_event"] = True
    raw = export_state(state)
    loaded = import_state(raw)
    assert loaded.inventory["gift_chocolate_01"] == 5
    assert loaded.executed_events["gift_secretary_once"] is True
    # 模拟 consume
    loaded.inventory["gift_chocolate_01"] -= 1
    assert loaded.inventory["gift_chocolate_01"] == 4
    again = import_state(export_state(loaded))
    assert again.inventory["gift_chocolate_01"] == 4
    return "PASS：inventory + executed_event_ids 往返；扣减后可再存档"


def main() -> None:
    rounds = [
        ("第 1 轮", round1_basic_roundtrip),
        ("第 2 轮", round2_schedule_ref_resolve),
        ("第 3 轮", round3_terminate_roster_schedule_orphan),
        ("第 4 轮", round4_version_migration_and_reject),
        ("第 5 轮", round5_inventory_and_flags_monotonic),
    ]
    print("=== Save v1 沙盘模拟（5 轮）===\n")
    for title, fn in rounds:
        msg = fn()
        print(f"{title}：{msg}")
    print("\n全部 5 轮通过。")


if __name__ == "__main__":
    main()
