#!/usr/bin/env python3
"""跟随/探望剧情触发沙盘（6 轮）。"""

from __future__ import annotations

from dataclasses import dataclass, field

TRIGGER_FOLLOW = 1
TRIGGER_VISIT = 2
MODE_SOLO = 0
MODE_PARALLEL = 1


@dataclass
class StoryEvent:
    event_id: str
    trigger_context: int
    trigger_mode: int
    task_signature: str = ""
    location_id: str = ""
    facility_id: str = ""
    trigger_chance: float = 1.0
    priority: int = 0
    affection_delta: int = 0


@dataclass
class GameStub:
    affection: dict[str, int] = field(default_factory=dict)
    executed: set[str] = field(default_factory=set)
    flags: dict[str, object] = field(default_factory=dict)
    schedules: dict[str, dict] = field(default_factory=dict)
    follow_today: dict[str, bool] = field(default_factory=dict)
    day_mode: str = "FREE"
    on_map: bool = False
    rng: float = 0.5


EVENTS = [
    StoryEvent("story_follow_gig_bar_01", TRIGGER_FOLLOW, MODE_SOLO, "gig:gig_bar_singer_01", priority=10, affection_delta=3),
    StoryEvent("story_follow_gig_bar_parallel", TRIGGER_FOLLOW, MODE_PARALLEL, "gig:gig_bar_singer_01", priority=20, affection_delta=2),
    StoryEvent("story_visit_bar_gig_01", TRIGGER_VISIT, MODE_SOLO, "gig:gig_bar_singer_01", "screen_2", "fac_bar", 0.85, 10, 2),
    StoryEvent("story_visit_tv_variety_01", TRIGGER_VISIT, MODE_SOLO, "job:test_job_tv_variety_01", "screen_2", "fac_tv_01", 0.9, 10, 2),
]


def compare_priority(a: str, b: str, game: GameStub) -> bool:
    aa, ab = game.affection.get(a, 0), game.affection.get(b, 0)
    if aa != ab:
        return aa > ab
    return a < b


def find_best_event(
    context: int,
    signature: str,
    location_id: str,
    facility_id: str,
    prefer_parallel: bool,
) -> StoryEvent | None:
    best: StoryEvent | None = None
    best_score = -1
    for ev in EVENTS:
        if ev.trigger_context != context:
            continue
        if ev.task_signature and signature and ev.task_signature != signature:
            continue
        if ev.location_id and location_id and ev.location_id != location_id:
            continue
        if ev.facility_id and facility_id and ev.facility_id != facility_id:
            continue
        score = ev.priority
        if context == TRIGGER_FOLLOW:
            if prefer_parallel and ev.trigger_mode == MODE_PARALLEL:
                score += 50
            elif not prefer_parallel and ev.trigger_mode == MODE_SOLO:
                score += 50
        if ev.task_signature and ev.task_signature == signature:
            score += 100
        elif not ev.task_signature:
            score += 10
        if score > best_score:
            best_score = score
            best = ev
    return best


def run_follow(game: GameStub, artist_ids: list[str]) -> dict:
    if game.day_mode != "FOLLOW":
        return {"success": False, "reason": "not_follow_day"}
    artist_ids = sorted(artist_ids, key=lambda x: (-game.affection.get(x, 0), x))
    sig = game.schedules.get(artist_ids[0], {}).get("signature", "")
    ev = find_best_event(TRIGGER_FOLLOW, sig, "", "", len(artist_ids) >= 2)
    if ev is None:
        return {"success": False, "reason": "no_matching_event"}
    if ev.trigger_mode == MODE_PARALLEL:
        primary = artist_ids[0]
        game.executed.add(ev.event_id)
        for aid in artist_ids:
            game.affection[aid] = game.affection.get(aid, 0) + ev.affection_delta
        return {"success": True, "mode": "PARALLEL", "participants": artist_ids, "event_id": ev.event_id}
    results = []
    for aid in artist_ids:
        if ev.event_id in game.executed:
            break
        game.executed.add(ev.event_id)
        game.affection[aid] = game.affection.get(aid, 0) + ev.affection_delta
        results.append(aid)
    return {"success": True, "mode": "SOLO", "participants": results, "event_id": ev.event_id}


def try_visit(game: GameStub, location_id: str, facility_id: str) -> dict:
    if game.day_mode != "FREE" or not game.on_map:
        return {"success": False, "reason": "blocked"}
    artists = [
        aid
        for aid, slot in game.schedules.items()
        if slot.get("location_id") == location_id
        and (not facility_id or slot.get("facility_id") == facility_id)
    ]
    artists.sort(key=lambda x: (-game.affection.get(x, 0), x))
    sig = game.schedules[artists[0]]["signature"] if artists else ""
    ev = find_best_event(TRIGGER_VISIT, sig, location_id, facility_id, False)
    if ev is None:
        return {"success": False, "reason": "no_matching_event"}
    if ev.task_signature and not artists:
        return {"success": False, "reason": "no_artist_at_location"}
    if game.rng > ev.trigger_chance:
        return {"success": False, "reason": "chance_failed"}
    target = artists[0] if artists else "npc"
    game.affection[target] = game.affection.get(target, 0) + ev.affection_delta
    return {"success": True, "mode": "SOLO", "participants": artists[:1], "event_id": ev.event_id}


def run_rounds() -> None:
    print("=== 跟随/探望剧情沙盘（6 轮）===\n")

    # 1. 单人跟随 → SOLO 事件
    g = GameStub(affection={"artist_001": 30}, day_mode="FOLLOW")
    g.schedules["artist_001"] = {"signature": "gig:gig_bar_singer_01"}
    r = run_follow(g, ["artist_001"])
    assert r["success"] and r["mode"] == "SOLO" and r["event_id"] == "story_follow_gig_bar_01"
    print("第 1 轮：PASS：单人跟随触发 SOLO 事件")

    # 2. 双人同 gig → PARALLEL 事件，好感全员 +2
    g = GameStub(affection={"artist_001": 40, "artist_002": 20}, day_mode="FOLLOW")
    for aid in ("artist_001", "artist_002"):
        g.schedules[aid] = {"signature": "gig:gig_bar_singer_01"}
    r = run_follow(g, ["artist_001", "artist_002"])
    assert r["success"] and r["mode"] == "PARALLEL" and r["event_id"] == "story_follow_gig_bar_parallel"
    assert g.affection["artist_001"] == 42 and g.affection["artist_002"] == 22
    print("第 2 轮：PASS：双人同任务 → PARALLEL，好感并列增加")

    # 3. 跟随排序：高好感优先
    g = GameStub(affection={"artist_001": 10, "artist_002": 50}, day_mode="FOLLOW")
    for aid in ("artist_001", "artist_002"):
        g.schedules[aid] = {"signature": "gig:gig_bar_singer_01"}
    r = run_follow(g, ["artist_002", "artist_001"])
    assert r["participants"][0] == "artist_002"
    print("第 3 轮：PASS：跟随名单按好感 → ID 排序")

    # 4. 探望：艺人在酒吧有 gig → 命中
    g = GameStub(affection={"artist_001": 0}, day_mode="FREE", on_map=True, rng=0.1)
    g.schedules["artist_001"] = {
        "signature": "gig:gig_bar_singer_01",
        "location_id": "screen_2",
        "facility_id": "fac_bar",
    }
    r = try_visit(g, "screen_2", "fac_bar")
    assert r["success"] and r["event_id"] == "story_visit_bar_gig_01"
    assert g.affection["artist_001"] == 2
    print("第 4 轮：PASS：探望匹配 location + gig 签名")

    # 5. 探望：无艺人 schedule → 不触发
    g = GameStub(day_mode="FREE", on_map=True, rng=0.1)
    r = try_visit(g, "screen_2", "fac_bar")
    assert not r["success"] and r["reason"] == "no_artist_at_location"
    print("第 5 轮：PASS：无艺人在场时不触发带 task_signature 的探望")

    # 6. 通告 JobInstance 地理绑定 → 探望电视台
    g = GameStub(affection={"artist_001": 0}, day_mode="FREE", on_map=True, rng=0.1)
    g.schedules["artist_001"] = {
        "signature": "job:test_job_tv_variety_01",
        "location_id": "screen_2",
        "facility_id": "fac_tv_01",
    }
    r = try_visit(g, "screen_2", "fac_tv_01")
    assert r["success"] and r["event_id"] == "story_visit_tv_variety_01"
    print("第 6 轮：PASS：通告 JobResource 地理绑定可触发探望")

    print(f"\n全部 6 轮通过。")


if __name__ == "__main__":
    run_rounds()
