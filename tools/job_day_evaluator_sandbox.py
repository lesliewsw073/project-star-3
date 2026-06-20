#!/usr/bin/env python3
"""
通告每日拍攝判定沙盘 — 极端情况模拟（纯 Python，镜像 JobDayEvaluator.gd）。
"""

from __future__ import annotations

import sys
from dataclasses import dataclass, field
from typing import Any

SHOOT_STAT_RATIO = 0.90
FAIL_FATIGUE_HARD = 85
FAIL_STRESS_HARD = 76
PERFECT_CAP = 0.50

ACCEPT_MODE_NORMAL = 0
ACCEPT_MODE_INVITE = 1

STAT_NAMES = [
    "empathy", "timbre", "improvisation", "acting", "singing", "eloquence",
    "dynamism", "talent", "stamina", "deportment", "fashion", "confidence",
    "rebelliousness", "humor", "affinity", "fame", "popularity", "exposure", "morality",
]

QUALITY_FAILED = 1
QUALITY_NORMAL = 2
QUALITY_PERFECT = 3


@dataclass
class MockJob:
    job_id: str = "job_test"
    add_fatigue: int = 20
    add_stress: int = 15
    reqs: dict[str, int] = field(default_factory=dict)


@dataclass
class MockJobInstance:
    base_job: MockJob
    accept_mode: int = ACCEPT_MODE_NORMAL
    accept_shoot_floor: dict[str, int] = field(default_factory=dict)


@dataclass
class MockArtist:
    stats: dict[str, int] = field(default_factory=dict)
    fatigue: int = 0
    stress: int = 0
    mood_state: str = "GREEN"  # GREEN | YELLOW | RED
    can_work: bool = True
    satisfaction: int = 50
    affection: int = 50
    fail_rate_abs: int = 0
    perfect_rate_abs: int = 0
    favor_gain_mod: int = 0


@dataclass
class EvalContext:
    forced_fail_global: bool = False
    forced_fail_jobs: set[str] = field(default_factory=set)


def build_floors(reqs: dict[str, int]) -> dict[str, int]:
    return {k: int(v * SHOOT_STAT_RATIO) for k, v in reqs.items() if v > 0}


def mood_fail_rate(stress: int, mood_state: str) -> float:
    if mood_state == "RED":
        return 1.0
    if mood_state == "YELLOW":
        extra = max(stress - 51, 0)
        return 0.10 + extra * 0.02
    return 0.0


def body_factor(fatigue: int, stress: int) -> float:
    lf = 1.0 - max(min(fatigue / 100.0, 1.0), 0.0)
    ls = 1.0 - max(min(stress / 100.0, 1.0), 0.0)
    return max(min(0.5 * lf + 0.5 * ls, 1.0), 0.0)


def state_hard_fail(artist: MockArtist, job: MockJob) -> str:
    if not artist.can_work:
        return "health_blocked"
    if artist.mood_state == "RED":
        return "stress_red"
    if artist.fatigue >= FAIL_FATIGUE_HARD:
        return "fatigue_hard"
    if artist.stress >= FAIL_STRESS_HARD:
        return "stress_hard"
    if artist.fatigue + job.add_fatigue >= FAIL_FATIGUE_HARD:
        return "fatigue_projected"
    if artist.stress + job.add_stress >= FAIL_STRESS_HARD:
        return "stress_projected"
    return ""


def stat_layer(artist: MockArtist, inst: MockJobInstance) -> dict[str, Any]:
    if inst.accept_mode == ACCEPT_MODE_NORMAL:
        return {"stat_pass": True, "stat_score": 1.0}
    floors = inst.accept_shoot_floor
    min_ratio = 999.0
    worst = ""
    for stat, floor in floors.items():
        current = artist.stats.get(stat, 0)
        ratio = current / max(floor, 1)
        if ratio < min_ratio:
            min_ratio = ratio
            worst = stat
    if min_ratio == 999.0:
        return {"stat_pass": True, "stat_score": 1.0}
    return {"stat_pass": min_ratio >= 1.0, "stat_score": min_ratio, "worst_stat": worst}


def p_fail(artist: MockArtist, bf: float) -> float:
    p_mood = mood_fail_rate(artist.stress, artist.mood_state)
    if artist.mood_state == "RED":
        return 0.95
    p_trait = artist.fail_rate_abs / 100.0
    p_body = (1.0 - bf) * 0.15
    return min(max(p_mood + p_trait + p_body, 0.0), 0.95)


def p_perfect(artist: MockArtist, stat_eval: dict, bf: float) -> float:
    stat_score = float(stat_eval.get("stat_score", 1.0))
    overflow = max(stat_score - 1.0, 0.0)
    stat_part = min(max(overflow / 0.5, 0.0), 1.0) * 0.20
    satisf = min(max(artist.satisfaction / 100.0, 0.0), 1.0) * 0.10
    lf = (1.0 - min(max(artist.fatigue / 100.0, 0.0), 1.0)) * 0.08
    ls = (1.0 - min(max(artist.stress / 100.0, 0.0), 1.0)) * 0.07
    aff_eff = artist.affection * (100 + artist.favor_gain_mod) / 100.0
    aff = min(max(aff_eff / 100.0, 0.0), 1.0) * 0.10
    p_trait = artist.perfect_rate_abs / 100.0
    base = (stat_part + satisf + lf + ls + aff) * bf
    return min(max(base + p_trait, 0.0), PERFECT_CAP)


def evaluate(
    artist: MockArtist,
    inst: MockJobInstance,
    ctx: EvalContext,
    rng_fail: float = 0.0,
    rng_perfect: float = 1.0,
) -> dict[str, Any]:
    job = inst.base_job
    if ctx.forced_fail_global or job.job_id in ctx.forced_fail_jobs:
        return {"quality": QUALITY_FAILED, "reason": "forced_event"}
    hard = state_hard_fail(artist, job)
    if hard:
        return {"quality": QUALITY_FAILED, "reason": hard}
    se = stat_layer(artist, inst)
    if not se["stat_pass"]:
        return {"quality": QUALITY_FAILED, "reason": "stat_below_shoot_floor", "stat_eval": se}
    bf = body_factor(artist.fatigue, artist.stress)
    pf = p_fail(artist, bf)
    if pf > 0 and rng_fail < pf:
        return {"quality": QUALITY_FAILED, "reason": "trait_or_mood_roll", "p_fail": pf}
    pp = p_perfect(artist, se, bf)
    q = QUALITY_NORMAL
    if pp > 0 and rng_perfect <= pp:
        q = QUALITY_PERFECT
    return {"quality": q, "reason": "ok", "p_fail": pf, "p_perfect": pp, "stat_eval": se}


def make_job(reqs: dict[str, int]) -> MockJobInstance:
    job = MockJob(reqs=reqs)
    return MockJobInstance(base_job=job, accept_shoot_floor=build_floors(reqs))


def make_artist(**kwargs: Any) -> MockArtist:
    stats = kwargs.pop("stats", {})
    return MockArtist(stats=stats, **kwargs)


def scenario_normal_gift_halved_stats() -> None:
    """疯狂送礼属性腰斩：NORMAL 接案后属性层仍通过。"""
    reqs = {"acting": 500, "fame": 400, "eloquence": 300}
    inst = make_job(reqs)
    inst.accept_mode = ACCEPT_MODE_NORMAL
    artist = make_artist(
        stats={"acting": 250, "fame": 200, "eloquence": 150},
        fatigue=30,
        stress=25,
    )
    r = evaluate(artist, inst, EvalContext(), rng_fail=0.99, rng_perfect=0.0)
    assert r["quality"] in (QUALITY_NORMAL, QUALITY_PERFECT), r
    assert r["reason"] != "stat_below_shoot_floor"


def scenario_invite_gift_halved_stats() -> None:
    """INVITE 接案后属性腰斩：应低于 90% floor 而失败。"""
    reqs = {"acting": 500, "fame": 400}
    inst = make_job(reqs)
    inst.accept_mode = ACCEPT_MODE_INVITE
    artist = make_artist(stats={"acting": 250, "fame": 200})
    r = evaluate(artist, inst, EvalContext())
    assert r["quality"] == QUALITY_FAILED
    assert r["reason"] == "stat_below_shoot_floor"


def scenario_invite_borderline_90() -> None:
    reqs = {"acting": 500}
    inst = make_job(reqs)
    inst.accept_mode = ACCEPT_MODE_INVITE
    floor = inst.accept_shoot_floor["acting"]  # 450
    artist_ok = make_artist(stats={"acting": floor}, fatigue=20, stress=20)
    artist_bad = make_artist(stats={"acting": floor - 1}, fatigue=20, stress=20)
    assert evaluate(artist_ok, inst, EvalContext(), rng_fail=0.99)["reason"] != "stat_below_shoot_floor"
    assert evaluate(artist_bad, inst, EvalContext())["reason"] == "stat_below_shoot_floor"


def scenario_fatigue_near_hospital() -> None:
    reqs = {"acting": 400}
    job = MockJob(reqs=reqs, add_fatigue=20)
    inst = MockJobInstance(base_job=job, accept_mode=ACCEPT_MODE_NORMAL, accept_shoot_floor=build_floors(reqs))
    artist = make_artist(stats={"acting": 400}, fatigue=64, stress=40)
    r = evaluate(artist, inst, EvalContext(), rng_fail=0.99)
    assert r["quality"] in (QUALITY_NORMAL, QUALITY_PERFECT), r

    artist_hard = make_artist(stats={"acting": 400}, fatigue=85, stress=40)
    assert evaluate(artist_hard, inst, EvalContext())["reason"] == "fatigue_hard"


def scenario_stress_near_sick() -> None:
    reqs = {"acting": 400}
    job = MockJob(reqs=reqs, add_stress=15)
    inst = MockJobInstance(base_job=job, accept_mode=ACCEPT_MODE_NORMAL, accept_shoot_floor=build_floors(reqs))
    artist = make_artist(stats={"acting": 400}, fatigue=40, stress=60, mood_state="YELLOW")
    r = evaluate(artist, inst, EvalContext(), rng_fail=0.99)
    assert r["quality"] in (QUALITY_NORMAL, QUALITY_PERFECT), r

    artist_red = make_artist(stats={"acting": 400}, fatigue=40, stress=80, mood_state="RED")
    assert evaluate(artist_red, inst, EvalContext())["reason"] == "stress_red"


def scenario_projected_fatigue_fail() -> None:
    reqs = {"acting": 400}
    job = MockJob(reqs=reqs, add_fatigue=20)
    inst = MockJobInstance(base_job=job, accept_mode=ACCEPT_MODE_NORMAL, accept_shoot_floor=build_floors(reqs))
    artist = make_artist(stats={"acting": 400}, fatigue=64, stress=30)
    assert evaluate(artist, inst, EvalContext(), rng_fail=0.99)["reason"] != "fatigue_projected"
    artist2 = make_artist(stats={"acting": 400}, fatigue=65, stress=30)
    assert evaluate(artist2, inst, EvalContext())["reason"] == "fatigue_projected"


def scenario_high_fail_trait_yellow_mood() -> None:
    inst = make_job({"acting": 500})
    inst.accept_mode = ACCEPT_MODE_NORMAL
    artist = make_artist(
        stats={"acting": 500},
        fatigue=60,
        stress=60,
        mood_state="YELLOW",
        fail_rate_abs=20,
    )
    bf = body_factor(artist.fatigue, artist.stress)
    pf = p_fail(artist, bf)
    assert pf >= 0.28
    r_fail = evaluate(artist, inst, EvalContext(), rng_fail=0.0)
    assert r_fail["quality"] == QUALITY_FAILED
    r_ok = evaluate(artist, inst, EvalContext(), rng_fail=0.99)
    assert r_ok["quality"] in (QUALITY_NORMAL, QUALITY_PERFECT)


def scenario_stats_high_state_crush_perfect() -> None:
    job = MockJob(reqs={"acting": 500}, add_fatigue=20, add_stress=15)
    inst = MockJobInstance(base_job=job, accept_mode=ACCEPT_MODE_NORMAL, accept_shoot_floor=build_floors(job.reqs))
    artist = make_artist(
        stats={"acting": 500},
        fatigue=64,
        stress=60,
        satisfaction=90,
        affection=90,
        perfect_rate_abs=0,
        mood_state="YELLOW",
    )
    bf = body_factor(artist.fatigue, artist.stress)
    se = stat_layer(artist, inst)
    pp = p_perfect(artist, se, bf)
    assert pp < 0.12, pp
    r = evaluate(artist, inst, EvalContext(), rng_fail=0.99, rng_perfect=1.0)
    assert r["quality"] == QUALITY_NORMAL, r


def scenario_perfect_roll_ceiling() -> None:
    inst = make_job({"acting": 500})
    inst.accept_mode = ACCEPT_MODE_INVITE
    artist = make_artist(
        stats={"acting": 750},
        fatigue=10,
        stress=10,
        satisfaction=100,
        affection=100,
        perfect_rate_abs=40,
    )
    se = stat_layer(artist, inst)
    pp = p_perfect(artist, se, body_factor(10, 10))
    assert pp == PERFECT_CAP


def scenario_forced_event() -> None:
    inst = make_job({"acting": 500})
    inst.accept_mode = ACCEPT_MODE_NORMAL
    artist = make_artist(stats={"acting": 500}, fatigue=10, stress=10)
    ctx = EvalContext(forced_fail_jobs={"job_test"})
    assert evaluate(artist, inst, ctx)["reason"] == "forced_event"


def scenario_sick_cannot_work() -> None:
    inst = make_job({"acting": 500})
    artist = make_artist(stats={"acting": 500}, can_work=False)
    assert evaluate(artist, inst, EvalContext())["reason"] == "health_blocked"


def main() -> None:
    print("=== job_day_evaluator_sandbox ===")
    scenarios = [
        ("NORMAL 接案后属性腰斩仍成功", scenario_normal_gift_halved_stats),
        ("INVITE 接案后属性腰斩失败", scenario_invite_gift_halved_stats),
        ("INVITE 90% 边界", scenario_invite_borderline_90),
        ("疲劳 64 可拍 / 65 预估超标", scenario_fatigue_near_hospital),
        ("压力 84 黄线 / RED 硬失败", scenario_stress_near_sick),
        ("预估疲劳超标", scenario_projected_fatigue_fail),
        ("高 fail_rate + 黄压力 Roll", scenario_high_fail_trait_yellow_mood),
        ("属性高但状态差完美率被压", scenario_stats_high_state_crush_perfect),
        ("完美率上限 50%", scenario_perfect_roll_ceiling),
        ("闹鬼事件必失败", scenario_forced_event),
        ("生病无法工作", scenario_sick_cannot_work),
    ]
    for title, fn in scenarios:
        fn()
        print(f"  [PASS] {title}")
    print("job_day_evaluator_sandbox 通過。")


if __name__ == "__main__":
    try:
        main()
    except AssertionError as exc:
        print(f"  [FAIL] {exc}")
        sys.exit(1)
