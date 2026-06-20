#!/usr/bin/env python3
"""StoryEvent：InteractionEventResource schema + 命名 + 目錄檢查。"""

from __future__ import annotations

import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
EVENT_RES = ROOT / "scripts/resources/InteractionEventResource.gd"
PLAYBACK = ROOT / "scripts/managers/StoryPlaybackController.gd"
TRIGGER = ROOT / "scripts/managers/StoryTriggerManager.gd"
PROJECT = ROOT / "project.godot"
EVENTS_DIR = ROOT / "data/story_events"
README = ROOT / "docs/writing/README_STORY.md"

EVENT_ID_PATTERN = re.compile(
    r"^story_(sign|meeting|follow|visit|map|calendar|main|hospital|award|phone|ending|duo|ensemble|schedule_result)_[a-z0-9_]+$"
)

SIGN_EVENTS = {
    "artist_001": "story_sign_artist_001_street_01",
    "artist_002": "story_sign_artist_002_theater_01",
    "artist_003": "story_sign_artist_003_day1_office_01",
}

MEETING_FIRST_SESSION = {
    "artist_001": "story_meeting_artist_001_first_session_01",
    "artist_002": "story_meeting_artist_002_first_session_01",
    "artist_003": "story_meeting_artist_003_first_session_01",
}

MEETING_WEEKLY_FLAVOR = "story_meeting_weekly_flavor_01"
SHOPKEEPER_INTRO = "story_visit_npc_shopkeeper_01_intro_01"
SHOPKEEPER_ENTER_EVENTS = {
    "story_visit_npc_shopkeeper_01_enter_01",
    "story_visit_npc_shopkeeper_01_enter_02",
    "story_visit_npc_shopkeeper_01_enter_03",
}

REQUIRED_RESOURCE = (
    "meeting_scope",
    "StoryChannel",
    "get_resolved_channel",
    "has_dialogue",
    "validate_config",
)


def _read(path: Path) -> str:
    return path.read_text(encoding="utf-8")


def check_resource_api() -> None:
    text = _read(EVENT_RES)
    for field in REQUIRED_RESOURCE:
        if field not in text:
            raise AssertionError(f"InteractionEventResource 缺少 {field}")


def check_playback_controller() -> None:
    text = _read(PLAYBACK)
    for token in ("playback_batch_finished", "enqueue_batch", "dialogue_finished"):
        if token not in text:
            raise AssertionError(f"StoryPlaybackController 缺少 {token}")
    if "start_story_lock" in text:
        raise AssertionError("StoryPlaybackController 不應把 blocking 劇情轉成跨日劇情鎖")


def check_trigger_manager() -> None:
    text = _read(TRIGGER)
    for fn in (
        "try_play_sign_story",
        "try_play_calendar_story",
        "try_play_meeting_story",
        "make_playback_batch",
        "_meeting_scope_matches",
    ):
        if fn not in text:
            raise AssertionError(f"StoryTriggerManager 缺少 {fn}()")
    if "InteractionManager.execute_event(template)" in text:
        raise AssertionError("StoryTriggerManager 不應再直接 execute_event")


def check_autoload() -> None:
    if "StoryPlaybackController=" not in _read(PROJECT):
        raise AssertionError("project.godot 未註冊 StoryPlaybackController")


def check_readme_story() -> None:
    if not README.is_file():
        raise AssertionError("缺少 docs/writing/README_STORY.md")
    text = _read(README)
    for token in ("event_id", "story_channel", "meeting_scope", "Obsidian"):
        if token not in text:
            raise AssertionError(f"README_STORY 缺少 {token} 说明")


def _parse_event_tres(path: Path) -> dict:
    text = _read(path)
    out: dict = {"path": path}
    m = re.search(r'^event_id\s*=\s*"(.*)"', text, re.M)
    out["event_id"] = m.group(1) if m else ""
    m_ch = re.search(r"^story_channel\s*=\s*(\d+)", text, re.M)
    out["story_channel"] = int(m_ch.group(1)) if m_ch else None
    m_scope = re.search(r'^meeting_scope\s*=\s*"(.*)"', text, re.M)
    out["meeting_scope"] = m_scope.group(1) if m_scope else ""
    m_owner = re.search(r'^owner\s*=\s*"(.*)"', text, re.M)
    out["owner"] = m_owner.group(1) if m_owner else ""
    m_loc = re.search(r'^location_id\s*=\s*"(.*)"', text, re.M)
    out["location_id"] = m_loc.group(1) if m_loc else ""
    m_fac = re.search(r'^facility_id\s*=\s*"(.*)"', text, re.M)
    out["facility_id"] = m_fac.group(1) if m_fac else ""
    m_pool = re.search(r'^pool_id\s*=\s*"(.*)"', text, re.M)
    out["pool_id"] = m_pool.group(1) if m_pool else ""
    out["has_dialogue"] = "dialogue = SubResource" in text or "dialogue = ExtResource" in text
    return out


def load_all_events() -> list[dict]:
    return [_parse_event_tres(p) for p in sorted(EVENTS_DIR.rglob("*.tres"))]


def check_event_ids_unique(events: list[dict]) -> None:
    ids = [e["event_id"] for e in events if e["event_id"]]
    if len(ids) != len(set(ids)):
        raise AssertionError(f"event_id 重複：{ids}")


def check_event_id_naming(events: list[dict]) -> None:
    for e in events:
        eid = e["event_id"]
        if not eid:
            continue
        if not EVENT_ID_PATTERN.match(eid):
            raise AssertionError(
                f"event_id 不符合命名规范：{eid}（见 docs/writing/README_STORY.md）"
            )


def check_follow_visit_exclusive(events: list[dict]) -> None:
    for e in events:
        ch = e.get("story_channel")
        if ch == 4:
            body = _read(e["path"])
            m = re.search(r'^facility_id\s*=\s*"(.+)"', body, re.M)
            if m and m.group(1).strip():
                raise AssertionError(f"{e['event_id']} follow 通道不应填 facility_id")


def check_sign_events(events: list[dict]) -> None:
    by_id = {e["event_id"]: e for e in events}
    for artist_id, event_id in SIGN_EVENTS.items():
        if event_id not in by_id:
            raise AssertionError(f"缺少 {event_id}")
        ev = by_id[event_id]
        if ev.get("story_channel") != 1:
            raise AssertionError(f"{event_id} story_channel 应为 SIGN(1)")
        if ev["owner"] != artist_id:
            raise AssertionError(f"{event_id} owner 应为 {artist_id}")
        if not ev["has_dialogue"]:
            raise AssertionError(f"{event_id} 应绑定 dialogue")
        rel = ev["path"].relative_to(EVENTS_DIR)
        if rel.parts[:3] != ("main", "artists", artist_id):
            raise AssertionError(f"{event_id} 路径应为 main/artists/{artist_id}/")


def check_meeting_first_sessions(events: list[dict]) -> None:
    by_id = {e["event_id"]: e for e in events}
    for artist_id, event_id in MEETING_FIRST_SESSION.items():
        if event_id not in by_id:
            raise AssertionError(f"缺少 {event_id}")
        ev = by_id[event_id]
        if ev.get("story_channel") != 3:
            raise AssertionError(f"{event_id} story_channel 应为 MEETING(3)")
        if ev.get("meeting_scope") != "first":
            raise AssertionError(f"{event_id} meeting_scope 应为 first")
        if ev["owner"] != artist_id:
            raise AssertionError(f"{event_id} owner 应为 {artist_id}")
        if not ev["has_dialogue"]:
            raise AssertionError(f"{event_id} 应绑定 dialogue")


def check_meeting_weekly_flavor(events: list[dict]) -> None:
    by_id = {e["event_id"]: e for e in events}
    if MEETING_WEEKLY_FLAVOR not in by_id:
        raise AssertionError(f"缺少 {MEETING_WEEKLY_FLAVOR}")
    ev = by_id[MEETING_WEEKLY_FLAVOR]
    if ev.get("story_channel") != 3:
        raise AssertionError(f"{MEETING_WEEKLY_FLAVOR} story_channel 应为 MEETING(3)")
    if ev.get("meeting_scope") != "weekly":
        raise AssertionError(f"{MEETING_WEEKLY_FLAVOR} meeting_scope 应为 weekly")
    if ev["owner"] != "secretary":
        raise AssertionError(f"{MEETING_WEEKLY_FLAVOR} owner 应为 secretary")
    if not ev["has_dialogue"]:
        raise AssertionError(f"{MEETING_WEEKLY_FLAVOR} 应绑定 dialogue")
    body = _read(ev["path"])
    if "execute_once = true" in body:
        raise AssertionError(f"{MEETING_WEEKLY_FLAVOR} 应为可重复 flavor（execute_once=false）")
    if not re.search(r"^cooldown_days\s*=\s*[1-9]", body, re.M):
        raise AssertionError(f"{MEETING_WEEKLY_FLAVOR} 应设 cooldown_days > 0")
    if "meeting.first_session_done" not in body:
        raise AssertionError(f"{MEETING_WEEKLY_FLAVOR} 应要求 meeting.first_session_done")


def check_shopkeeper_visit_events(events: list[dict]) -> None:
    by_id = {e["event_id"]: e for e in events}
    if SHOPKEEPER_INTRO not in by_id:
        raise AssertionError(f"缺少 {SHOPKEEPER_INTRO}")
    intro = by_id[SHOPKEEPER_INTRO]
    if intro.get("story_channel") != 5:
        raise AssertionError(f"{SHOPKEEPER_INTRO} story_channel 应为 VISIT(5)")
    if intro["owner"] != "npc_shopkeeper_01":
        raise AssertionError(f"{SHOPKEEPER_INTRO} owner 应为 npc_shopkeeper_01")
    if intro["location_id"] != "screen_1" or intro["facility_id"] != "fac_shop":
        raise AssertionError(f"{SHOPKEEPER_INTRO} 应绑定 screen_1/fac_shop")
    body = _read(intro["path"])
    if "execute_once = true" not in body:
        raise AssertionError(f"{SHOPKEEPER_INTRO} 应为首次一次性剧情")
    if '"shopkeeper_intro_done": true' not in body:
        raise AssertionError(f"{SHOPKEEPER_INTRO} 应设置 shopkeeper_intro_done")

    for event_id in SHOPKEEPER_ENTER_EVENTS:
        if event_id not in by_id:
            raise AssertionError(f"缺少 {event_id}")
        ev = by_id[event_id]
        if ev.get("story_channel") != 5:
            raise AssertionError(f"{event_id} story_channel 应为 VISIT(5)")
        if ev["owner"] != "npc_shopkeeper_01":
            raise AssertionError(f"{event_id} owner 应为 npc_shopkeeper_01")
        if ev["location_id"] != "screen_1" or ev["facility_id"] != "fac_shop":
            raise AssertionError(f"{event_id} 应绑定 screen_1/fac_shop")
        if ev["pool_id"] != "shop_enter":
            raise AssertionError(f"{event_id} pool_id 应为 shop_enter")
        enter_body = _read(ev["path"])
        if '"shopkeeper_intro_done": true' not in enter_body:
            raise AssertionError(f"{event_id} 应要求 shopkeeper_intro_done")


def main() -> None:
    print("=== story_event_sandbox ===")
    check_resource_api()
    print("  [PASS] InteractionEventResource schema")
    check_playback_controller()
    print("  [PASS] StoryPlaybackController")
    check_trigger_manager()
    print("  [PASS] StoryTriggerManager")
    check_autoload()
    print("  [PASS] Autoload")
    check_readme_story()
    print("  [PASS] README_STORY.md")
    events = load_all_events()
    if len(events) < 10:
        raise AssertionError(f"story_events 至少 10 则，实际 {len(events)}")
    check_event_ids_unique(events)
    print(f"  [PASS] {len(events)} 则 event_id 唯一")
    check_event_id_naming(events)
    print("  [PASS] event_id 命名规范")
    check_follow_visit_exclusive(events)
    print("  [PASS] follow/visit 互斥字段")
    check_sign_events(events)
    print("  [PASS] 001～003 sign 事件")
    check_meeting_first_sessions(events)
    print("  [PASS] 001～003 首次周会")
    check_meeting_weekly_flavor(events)
    print("  [PASS] 週會 flavor 占位")
    check_shopkeeper_visit_events(events)
    print("  [PASS] 商店首次與進店日常")
    print("story_event_sandbox 通過。")


if __name__ == "__main__":
    try:
        main()
    except AssertionError as exc:
        print(f"  [FAIL] {exc}")
        sys.exit(1)
