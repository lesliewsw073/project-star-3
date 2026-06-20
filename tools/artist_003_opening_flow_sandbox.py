#!/usr/bin/env python3
"""米语（artist_003）开局剧情链沙盘：sign → first meeting。"""

from __future__ import annotations

import re
import sys
from dataclasses import dataclass, field
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
EVENTS_DIR = ROOT / "data/story_events"
ARTIST_003_TRES = ROOT / "data/artists/artist_003/artist_003.tres"
GAME_ROOT = ROOT / "scripts/controllers/GameRootController.gd"
TRIGGER_MGR = ROOT / "scripts/managers/StoryTriggerManager.gd"

CHANNEL_SIGN = 1
CHANNEL_MEETING = 3

SIGN_ID = "story_sign_artist_003_day1_office_01"
MEETING_FIRST_SESSION_ID = "story_meeting_artist_003_first_session_01"
ARTIST_001_SIGN_ID = "story_sign_artist_001_street_01"
ARTIST_001_MEETING_ID = "story_meeting_artist_001_first_session_01"


@dataclass
class StoryEvent:
    event_id: str
    story_channel: int
    owner: str = ""
    meeting_scope: str = ""
    priority: int = 0
    execute_once: bool = False
    required_flags: dict[str, object] = field(default_factory=dict)
    flag_changes: dict[str, object] = field(default_factory=dict)
    has_dialogue: bool = False


def _read(path: Path) -> str:
    return path.read_text(encoding="utf-8")


def _parse_dict_field(text: str, field_name: str) -> dict[str, object]:
    m = re.search(rf"^{field_name}\s*=\s*(\{{.*\}})", text, re.M)
    if not m:
        return {}
    raw = m.group(1)
    out: dict[str, object] = {}
    for pair in re.findall(r'"([^"]+)"\s*:\s*([^,}]+)', raw):
        key, val = pair
        val = val.strip()
        if val in ("true", "false"):
            out[key] = val == "true"
        else:
            try:
                out[key] = int(val)
            except ValueError:
                out[key] = val.strip('"')
    return out


def load_story_events() -> dict[str, StoryEvent]:
    events: dict[str, StoryEvent] = {}
    for path in sorted(EVENTS_DIR.rglob("*.tres")):
        text = _read(path)
        m_id = re.search(r'^event_id\s*=\s*"(.*)"', text, re.M)
        if not m_id:
            continue
        m_ch = re.search(r"^story_channel\s*=\s*(\d+)", text, re.M)
        m_owner = re.search(r'^owner\s*=\s*"(.*)"', text, re.M)
        m_scope = re.search(r'^meeting_scope\s*=\s*"(.*)"', text, re.M)
        m_pri = re.search(r"^priority\s*=\s*(\d+)", text, re.M)
        events[m_id.group(1)] = StoryEvent(
            event_id=m_id.group(1),
            story_channel=int(m_ch.group(1)) if m_ch else -1,
            owner=m_owner.group(1) if m_owner else "",
            meeting_scope=m_scope.group(1) if m_scope else "",
            priority=int(m_pri.group(1)) if m_pri else 0,
            execute_once="execute_once = true" in text,
            required_flags=_parse_dict_field(text, "required_flags"),
            flag_changes=_parse_dict_field(text, "flag_changes"),
            has_dialogue="dialogue = SubResource" in text or "dialogue = ExtResource" in text,
        )
    return events


def flags_mismatch(ev: StoryEvent, flags: dict[str, object]) -> str:
    for key, expected in ev.required_flags.items():
        actual = flags.get(key, False)
        if actual != expected:
            return f"{key} need {expected} got {actual}"
    return ""


def owner_matches(ev: StoryEvent, query_owner: str) -> bool:
    if not ev.owner or not query_owner:
        return True
    return ev.owner == query_owner


def meeting_scope_matches(ev: StoryEvent, is_first_meeting: bool) -> bool:
    scope = ev.meeting_scope.strip().lower()
    if not scope:
        return True
    if scope == "first":
        return is_first_meeting
    if scope == "weekly":
        return not is_first_meeting
    return True


def find_best_event(
    events: dict[str, StoryEvent],
    channel: int,
    query_owner: str = "",
    is_first_meeting: bool = False,
    executed: set[str] | None = None,
) -> StoryEvent | None:
    executed = executed or set()
    best: StoryEvent | None = None
    best_score = -1
    for ev in events.values():
        if ev.story_channel != channel:
            continue
        if ev.execute_once and ev.event_id in executed:
            continue
        if not owner_matches(ev, query_owner):
            continue
        if flags_mismatch(ev, {} if executed is None else {}):
            pass
        if not meeting_scope_matches(ev, is_first_meeting):
            continue
        score = ev.priority
        if channel == CHANNEL_MEETING:
            scope = ev.meeting_scope.strip().lower()
            if is_first_meeting and scope == "first":
                score += 100
            elif not is_first_meeting and scope == "weekly":
                score += 50
        if score > best_score:
            best_score = score
            best = ev
    return best


def find_best_event_with_flags(
    events: dict[str, StoryEvent],
    channel: int,
    flags: dict[str, object],
    query_owner: str = "",
    is_first_meeting: bool = False,
    executed: set[str] | None = None,
) -> StoryEvent | None:
    executed = executed or set()
    best: StoryEvent | None = None
    best_score = -1
    for ev in events.values():
        if ev.story_channel != channel:
            continue
        if ev.execute_once and ev.event_id in executed:
            continue
        if not owner_matches(ev, query_owner):
            continue
        if flags_mismatch(ev, flags):
            continue
        if not meeting_scope_matches(ev, is_first_meeting):
            continue
        score = ev.priority
        if channel == CHANNEL_MEETING:
            scope = ev.meeting_scope.strip().lower()
            if is_first_meeting and scope == "first":
                score += 100
            elif not is_first_meeting and scope == "weekly":
                score += 50
        if score > best_score:
            best_score = score
            best = ev
    return best


def apply_flags(flags: dict[str, object], changes: dict[str, object]) -> None:
    for key, val in changes.items():
        flags[key] = val


def simulate_artist_003_opening(events: dict[str, StoryEvent]) -> list[str]:
    flags: dict[str, object] = {"opening_pick": "artist_003"}
    executed: set[str] = set()
    chain: list[str] = []

    sign = find_best_event_with_flags(
        events, CHANNEL_SIGN, flags, query_owner="artist_003", executed=executed
    )
    if sign is None or sign.event_id != SIGN_ID:
        raise AssertionError(f"签约应触发 {SIGN_ID}，实际 {sign}")
    if not sign.has_dialogue:
        raise AssertionError(f"{SIGN_ID} 应绑定 dialogue")
    chain.append(sign.event_id)
    executed.add(sign.event_id)
    apply_flags(flags, sign.flag_changes)

    meeting = find_best_event_with_flags(
        events,
        CHANNEL_MEETING,
        flags,
        query_owner="artist_003",
        is_first_meeting=True,
        executed=executed,
    )
    if meeting is None or meeting.event_id != MEETING_FIRST_SESSION_ID:
        raise AssertionError(
            f"首次周会应触发 {MEETING_FIRST_SESSION_ID}，实际 {getattr(meeting, 'event_id', None)}"
        )
    chain.append(meeting.event_id)
    executed.add(meeting.event_id)
    apply_flags(flags, meeting.flag_changes)

    if flags.get("meeting.first_session_done") is not True:
        raise AssertionError("米语首次周会后应设置 meeting.first_session_done")

    return chain


def simulate_artist_001_opening(events: dict[str, StoryEvent]) -> list[str]:
    flags: dict[str, object] = {"opening_pick": "artist_001"}
    executed: set[str] = set()
    chain: list[str] = []

    sign = find_best_event_with_flags(
        events, CHANNEL_SIGN, flags, query_owner="artist_001", executed=executed
    )
    if sign is None:
        raise AssertionError("artist_001 缺少 sign 事件")
    if sign.event_id != ARTIST_001_SIGN_ID:
        raise AssertionError(f"artist_001 签约应触发 {ARTIST_001_SIGN_ID}，实际 {sign.event_id}")
    chain.append(sign.event_id)
    executed.add(sign.event_id)
    apply_flags(flags, sign.flag_changes)

    meeting = find_best_event_with_flags(
        events,
        CHANNEL_MEETING,
        flags,
        query_owner="artist_001",
        is_first_meeting=True,
        executed=executed,
    )
    if meeting is None or meeting.event_id != ARTIST_001_MEETING_ID:
        raise AssertionError(
            f"artist_001 首次周会应为 {ARTIST_001_MEETING_ID}，实际 {getattr(meeting, 'event_id', None)}"
        )
    chain.append(meeting.event_id)
    return chain


def check_artist_003_resource() -> None:
    text = _read(ARTIST_003_TRES)
    if 'artist_name = "米语"' not in text:
        raise AssertionError("artist_003.tres artist_name 应为 米语")
    paths = _read(ROOT / "scripts/resources/CharacterVisualPaths.gd")
    if "_avatar.png" not in paths or "_portrait.png" not in paths:
        raise AssertionError("CharacterVisualPaths 应约定 avatar/portrait 标准文件名")
    avatar_dir = ROOT / "assets/characters/artists/artist_003/avatar"
    portrait_dir = ROOT / "assets/characters/artists/artist_003/portrait"
    cg_dir = ROOT / "assets/characters/artists/artist_003/cg"
    if not avatar_dir.is_dir() or not portrait_dir.is_dir() or not cg_dir.is_dir():
        raise AssertionError("artist_003 缺少 avatar/portrait/cg 资料夹")
    cg_path = cg_dir / "artist_003_cg_sign_knock_office.png"
    if not cg_path.is_file():
        raise AssertionError("artist_003 缺签约敲门 CG：artist_003_cg_sign_knock_office.png")
    sign = _read(EVENTS_DIR / "main/artists/artist_003/00_office_sign_01.tres")
    if 'cg_id = "sign_knock_office"' not in sign:
        raise AssertionError("artist_003 签约事件应设置 cg_id = sign_knock_office")
    if "age = 22" not in text:
        raise AssertionError("artist_003 profile age 应为 22")
    if "height_cm = 167" not in text:
        raise AssertionError("artist_003 profile height 应为 167")


def check_runtime_wiring() -> None:
    trigger = _read(TRIGGER_MGR)
    if "try_play_sign_story" not in trigger or "try_play_meeting_story" not in trigger:
        raise AssertionError("StoryTriggerManager 缺少签约/会议触发 API")

    root = _read(GAME_ROOT)
    for token in (
        "_start_opening_sign_story",
        "try_play_sign_story",
        "_try_enter_first_meeting_after_sign",
    ):
        if token not in root:
            raise AssertionError(f"GameRootController 缺少 {token}")
    bridge = ROOT / "scripts/ui/StoryBeatTransition.gd"
    if not bridge.is_file():
        raise AssertionError("缺少 StoryBeatTransition.gd")
    bridge_text = _read(bridge)
    if "sign_knock_office" not in bridge_text:
        raise AssertionError("StoryBeatTransition 应使用 sign_knock_office CG")


def main() -> None:
    print("=== artist_003_opening_flow_sandbox ===")
    check_artist_003_resource()
    print("  [PASS] artist_003.tres 人设与立绘")
    check_runtime_wiring()
    print("  [PASS] sign → first meeting 接线")
    events = load_story_events()
    for eid in (SIGN_ID, MEETING_FIRST_SESSION_ID, ARTIST_001_SIGN_ID, ARTIST_001_MEETING_ID):
        if eid not in events:
            raise AssertionError(f"缺少事件 {eid}")

    chain_003 = simulate_artist_003_opening(events)
    print(f"  [PASS] 米语剧情链：{' → '.join(chain_003)}")

    chain_001 = simulate_artist_001_opening(events)
    print(f"  [PASS] artist_001 对照链：{' → '.join(chain_001)}")

    print("artist_003_opening_flow_sandbox 通過。")


if __name__ == "__main__":
    try:
        main()
    except AssertionError as exc:
        print(f"  [FAIL] {exc}")
        sys.exit(1)
