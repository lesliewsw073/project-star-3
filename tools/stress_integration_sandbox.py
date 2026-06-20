#!/usr/bin/env python3
"""
整合壓力測試 — 高輪次邏輯模擬（不依賴 Godot）。
覆蓋：商店購買、週會送禮、秘書拒禮、通告孤兒行程、日循環重入、存檔往返。
"""

from __future__ import annotations

import copy
import json
import random
import sys
import time
from dataclasses import dataclass, field
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent

SECRETARY_ID = "secretary"
ARTIST_ID = "artist_001"
COMPANY_ITEMS = {
    "comp_item_meeting_plant_01": {"price": 3000, "rep": 50, "op": 0},
    "comp_item_meeting_sofa_02": {"price": 12000, "rep": 100, "op": 20},
}
BAG_ITEMS = {
    "attr_item_energy_drink_01": {"price": 200, "cat": "ATTRIBUTE"},
    "attr_item_perfume_01": {"price": 800, "cat": "ATTRIBUTE"},
}
SHOP_IDS = list(COMPANY_ITEMS) + list(BAG_ITEMS)

DAY_MODE_FREE = 2
DAY_MODE_FOLLOW = 1
GAME_PHASE_DAY = "DAY_OPERATION"


# ---------------------------------------------------------------------------
# 迷你經濟／道具鏡像
# ---------------------------------------------------------------------------
@dataclass
class EconomyState:
    money: int = 500_000
    inventory: dict[str, int] = field(default_factory=dict)
    company_owned: list[str] = field(default_factory=list)
    applied_rep: int = 0
    applied_op: int = 0
    reputation: int = 0
    public_opinion: int = 0
    secretary_gift_attempts: int = 0
    secretary_gift_blocked: int = 0


def _company_max_bonus(owned: list[str], kind: str) -> int:
    best = 0
    for oid in owned:
        item = COMPANY_ITEMS.get(oid)
        if not item:
            continue
        best = max(best, item["rep" if kind == "rep" else "op"])
    return best


def try_purchase(state: EconomyState, item_id: str) -> dict:
    if item_id in COMPANY_ITEMS:
        if item_id in state.company_owned:
            return {"success": False, "reason": "已持有"}
        price = COMPANY_ITEMS[item_id]["price"]
        if state.money < price:
            return {"success": False, "reason": "金幣不足"}
        state.money -= price
        state.company_owned.append(item_id)
        new_rep = _company_max_bonus(state.company_owned, "rep")
        new_op = _company_max_bonus(state.company_owned, "op")
        d_rep = new_rep - state.applied_rep
        d_op = new_op - state.applied_op
        state.applied_rep = new_rep
        state.applied_op = new_op
        state.reputation += d_rep
        state.public_opinion += d_op
        return {"success": True, "category": "COMPANY"}

    if item_id in BAG_ITEMS:
        price = BAG_ITEMS[item_id]["price"]
        if state.money < price:
            return {"success": False, "reason": "金幣不足"}
        state.money -= price
        state.inventory[item_id] = state.inventory.get(item_id, 0) + 1
        return {"success": True, "category": "ATTRIBUTE"}

    return {"success": False, "reason": "未知"}


def try_gift_to_artist(state: EconomyState, item_id: str, artist_id: str) -> dict:
    if artist_id == SECRETARY_ID:
        state.secretary_gift_attempts += 1
        state.secretary_gift_blocked += 1
        return {"success": False, "reason": "秘書不可收禮"}
    if artist_id != ARTIST_ID:
        return {"success": False, "reason": "未簽約"}
    count = state.inventory.get(item_id, 0)
    if count <= 0:
        return {"success": False, "reason": "物品欄沒有"}
    state.inventory[item_id] = count - 1
    if state.inventory[item_id] <= 0:
        state.inventory.pop(item_id, None)
    return {"success": True}


# ---------------------------------------------------------------------------
# 通告孤兒行程鏡像
# ---------------------------------------------------------------------------
@dataclass
class JobInstance:
    job_id: str
    status: str = "SHOOTING"
    qualified_days: int = 0


@dataclass
class JobManagerState:
    active_jobs: dict[str, JobInstance] = field(default_factory=dict)
    next_token: int = 0


def accept_job(jm: JobManagerState, job_id: str) -> tuple[str, JobInstance]:
    jm.next_token += 1
    inst = JobInstance(job_id=job_id)
    iid = f"{job_id}_{jm.next_token}"
    jm.active_jobs[iid] = inst
    return iid, inst


def clear_job_from_schedules(schedule: dict[int, JobInstance | None], inst: JobInstance) -> int:
    cleared = 0
    for day in list(schedule.keys()):
        if schedule[day] is inst:
            schedule[day] = None
            cleared += 1
    return cleared


def settle_completed(jm: JobManagerState, iid: str, schedule: dict[int, JobInstance | None]) -> None:
    inst = jm.active_jobs.pop(iid, None)
    if inst is None:
        return
    inst.status = "COMPLETED"
    clear_job_from_schedules(schedule, inst)


def process_shoot_day(
    jm: JobManagerState,
    schedule: dict[int, JobInstance | None],
    day: int,
) -> dict:
    inst = schedule.get(day)
    if inst is None:
        return {"skipped": True, "reason": "empty"}
    if inst.status in ("COMPLETED", "CANCELED"):
        schedule[day] = None
        return {"skipped": True, "reason": "already_settled"}
    if not any(v is inst for v in jm.active_jobs.values()):
        schedule[day] = None
        return {"skipped": True, "reason": "orphan"}
    inst.qualified_days += 1
    if inst.qualified_days >= 1:
        inst.status = "COMPLETED"
        iid = next(k for k, v in jm.active_jobs.items() if v is inst)
        settle_completed(jm, iid, schedule)
        return {"completed": True}
    return {"processed": True}


# ---------------------------------------------------------------------------
# 日循環重入鏡像（簡化 GameFlowManager v2）
# ---------------------------------------------------------------------------
@dataclass
class FlowState:
    is_transitioning: bool = False
    day_settlement_done: bool = False
    is_exploring_map: bool = False
    queued: list[str] = field(default_factory=list)
    finish_calls: int = 0


def finish_today(state: FlowState, mode: int) -> str:
    if state.is_transitioning:
        state.queued.append("finish_today")
        return "requeued"
    state.is_transitioning = True
    try:
        state.finish_calls += 1
        if mode == DAY_MODE_FREE and not state.day_settlement_done:
            state.is_exploring_map = False
            state.day_settlement_done = True
            return "work_report"
        if mode == DAY_MODE_FOLLOW:
            return "follow_done"
        return "end_day"
    finally:
        state.is_transitioning = False
        if state.queued:
            state.queued.pop(0)


# ---------------------------------------------------------------------------
# 壓力場景
# ---------------------------------------------------------------------------
def stress_shop_and_gift(rounds: int, seed: int) -> float:
    rng = random.Random(seed)
    state = EconomyState()
    purchases = 0
    gifts = 0
    t0 = time.perf_counter()
    for _ in range(rounds):
        if state.money < 2000:
            state.money = 500_000
        item_id = rng.choice(SHOP_IDS)
        result = try_purchase(state, item_id)
        if result.get("success"):
            purchases += 1
        bag_id = rng.choice(list(BAG_ITEMS))
        try_gift_to_artist(state, bag_id, SECRETARY_ID)
        if state.inventory.get(bag_id, 0) > 0:
            g = try_gift_to_artist(state, bag_id, ARTIST_ID)
            if g.get("success"):
                gifts += 1
    elapsed = time.perf_counter() - t0
    if state.secretary_gift_blocked != rounds:
        raise AssertionError(f"秘書應拒絕 {rounds} 次，實際 {state.secretary_gift_blocked}")
    if purchases < 500:
        raise AssertionError(f"購買成功次數過低：{purchases}/{rounds}")
    if gifts < 200:
        raise AssertionError(f"贈禮成功次數過低：{gifts}/{rounds}")
    if state.money < 0:
        raise AssertionError("金幣為負")
    return elapsed


def stress_job_orphan_schedule(rounds: int, seed: int) -> float:
    rng = random.Random(seed)
    orphan_hits = 0
    t0 = time.perf_counter()
    for _ in range(rounds):
        jm = JobManagerState()
        _, inst = accept_job(jm, "test_job_tv_01")
        schedule: dict[int, JobInstance | None] = {d: inst for d in range(7)}
        # 週一殺青
        r0 = process_shoot_day(jm, schedule, 0)
        if not r0.get("completed"):
            raise AssertionError("首日應殺青")
        # 週二～週日應靜默跳過（格已清）
        for day in range(1, 7):
            r = process_shoot_day(jm, schedule, day)
            if not r.get("skipped"):
                raise AssertionError(f"day {day} 應 skipped，得 {r}")
            orphan_hits += 1
    elapsed = time.perf_counter() - t0
    expected = rounds * 6
    if orphan_hits != expected:
        raise AssertionError(f"孤兒跳過應 {expected}，得 {orphan_hits}")
    return elapsed


def stress_day_cycle_reentry(rounds: int) -> float:
    t0 = time.perf_counter()
    requeues = 0
    for _ in range(rounds):
        st = FlowState()
        st.is_transitioning = True
        r1 = finish_today(st, DAY_MODE_FREE)
        if r1 != "requeued":
            raise AssertionError("重入應 requeue")
        requeues += 1
        st.is_transitioning = False
        r2 = finish_today(st, DAY_MODE_FREE)
        if r2 != "work_report":
            raise AssertionError(f"第二次應 work_report，得 {r2}")
        if st.finish_calls != 1:
            raise AssertionError("不應重複結算")
    elapsed = time.perf_counter() - t0
    if requeues != rounds:
        raise AssertionError("requeue 計數不符")
    return elapsed


def stress_save_inventory_roundtrip(rounds: int) -> float:
    t0 = time.perf_counter()
    for i in range(rounds):
        payload = {
            "save_version": 1,
            "inventory": {
                "attr_item_energy_drink_01": i % 50,
                "attr_item_perfume_01": (i * 3) % 20,
            },
            "company_items": {
                "owned_ids": ["comp_item_meeting_plant_01"] if i % 2 == 0 else [],
                "applied_reputation_bonus": 50 if i % 2 == 0 else 0,
                "applied_public_opinion_bonus": 0,
            },
            "player": {"company_public_opinion": i % 100},
        }
        blob = json.dumps(payload, ensure_ascii=False)
        loaded = json.loads(blob)
        if loaded["inventory"]["attr_item_energy_drink_01"] != i % 50:
            raise AssertionError("inventory 往返失敗")
    elapsed = time.perf_counter() - t0
    return elapsed


def main() -> None:
    print("=== stress_integration_sandbox ===\n")
    total_t0 = time.perf_counter()

    scenarios = [
        ("商店購買 + 秘書拒禮 + 藝人贈禮", stress_shop_and_gift, 5000, 20260618),
        ("通告殺青後孤兒行程清除", stress_job_orphan_schedule, 2000, 42),
        ("日循環 finish_today 重入護欄", stress_day_cycle_reentry, 3000, None),
        ("存檔 inventory 往返", stress_save_inventory_roundtrip, 8000, None),
    ]

    for label, fn, rounds, seed in scenarios:
        if seed is not None:
            elapsed = fn(rounds, seed)
        else:
            elapsed = fn(rounds)
        rate = rounds / elapsed if elapsed > 0 else float("inf")
        print(f"  [PASS] {label} ×{rounds} — {elapsed:.3f}s ({rate:,.0f} ops/s)")

    total = time.perf_counter() - total_t0
    print(f"\nstress_integration_sandbox 全部通過（總計 {total:.2f}s）。")


if __name__ == "__main__":
    try:
        main()
    except AssertionError as exc:
        print(f"  [FAIL] {exc}")
        sys.exit(1)
