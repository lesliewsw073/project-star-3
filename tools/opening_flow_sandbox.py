#!/usr/bin/env python3
"""开局三选一 + sign → first meeting 剧情链沙盘（20 轮）。"""

from __future__ import annotations

import re
import sys
from dataclasses import dataclass, field
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
EVENTS_DIR = ROOT / "data/story_events"
OPENING_PICK = ROOT / "scripts/ui/OpeningArtistPickDialog.gd"
GAME_ROOT = ROOT / "scripts/controllers/GameRootController.gd"
STORY_TRANSITION = ROOT / "scripts/ui/StoryBeatTransition.gd"
TRIGGER_MGR = ROOT / "scripts/managers/StoryTriggerManager.gd"

CHANNEL_SIGN = 1
CHANNEL_MEETING = 3

SIGN_IDS = {
    "artist_001": "story_sign_artist_001_street_01",
    "artist_002": "story_sign_artist_002_theater_01",
    "artist_003": "story_sign_artist_003_day1_office_01",
}
MEETING_IDS = {
    "artist_001": "story_meeting_artist_001_first_session_01",
    "artist_002": "story_meeting_artist_002_first_session_01",
    "artist_003": "story_meeting_artist_003_first_session_01",
}
ACTION_LABELS = ("下樓透透氣", "去看場舞台劇", "打開電視看看")
ROUNDS = 20


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
    path: Path | None = None


def _read(path: Path) -> str:
    return path.read_text(encoding="utf-8")


def _parse_dict_field(text: str, field_name: str) -> dict[str, object]:
    m = re.search(rf"^{field_name}\s*=\s*(\{{.*\}})", text, re.M)
    if not m:
        return {}
    out: dict[str, object] = {}
    for pair in re.findall(r'"([^"]+)"\s*:\s*([^,}]+)', m.group(1)):
        key, val = pair
        val = val.strip()
        if val in ("true", "false"):
            out[key] = val == "true"
        else:
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
        eid = m_id.group(1)
        events[eid] = StoryEvent(
            event_id=eid,
            story_channel=int(m_ch.group(1)) if m_ch else -1,
            owner=m_owner.group(1) if m_owner else "",
            meeting_scope=m_scope.group(1) if m_scope else "",
            priority=int(m_pri.group(1)) if m_pri else 0,
            execute_once="execute_once = true" in text,
            required_flags=_parse_dict_field(text, "required_flags"),
            flag_changes=_parse_dict_field(text, "flag_changes"),
            has_dialogue="dialogue = SubResource" in text or "dialogue = ExtResource" in text,
            path=path,
        )
    return events


def flags_mismatch(ev: StoryEvent, flags: dict[str, object]) -> bool:
    for key, expected in ev.required_flags.items():
        if flags.get(key) != expected:
            return True
    return False


def find_best(
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
        if query_owner and ev.owner and ev.owner != query_owner:
            continue
        if flags_mismatch(ev, flags):
            continue
        if channel == CHANNEL_MEETING:
            scope = ev.meeting_scope.strip().lower()
            if scope == "first" and not is_first_meeting:
                continue
            if scope == "weekly" and is_first_meeting:
                continue
        score = ev.priority
        if channel == CHANNEL_MEETING and scope == "first" and is_first_meeting:
            score += 100
        if score > best_score:
            best_score = score
            best = ev
    return best


def apply_flags(flags: dict[str, object], changes: dict[str, object]) -> None:
    for key, val in changes.items():
        flags[key] = val


def simulate_opening_chain(events: dict[str, StoryEvent], artist_id: str) -> list[str]:
    flags: dict[str, object] = {"opening_pick": artist_id}
    executed: set[str] = set()
    chain: list[str] = []

    sign = find_best(events, CHANNEL_SIGN, flags, query_owner=artist_id, executed=executed)
    expected_sign = SIGN_IDS[artist_id]
    if sign is None or sign.event_id != expected_sign:
        raise AssertionError(f"{artist_id} sign 应为 {expected_sign}，实际 {getattr(sign, 'event_id', None)}")
    if not sign.has_dialogue:
        raise AssertionError(f"{expected_sign} 应绑定 dialogue")
    chain.append(sign.event_id)
    executed.add(sign.event_id)
    apply_flags(flags, sign.flag_changes)

    sign_flag = f"sign_{artist_id}_done"
    if flags.get(sign_flag) is not True:
        raise AssertionError(f"sign 后应设置 {sign_flag}")

    meeting = find_best(
        events,
        CHANNEL_MEETING,
        flags,
        query_owner=artist_id,
        is_first_meeting=True,
        executed=executed,
    )
    expected_meeting = MEETING_IDS[artist_id]
    if meeting is None or meeting.event_id != expected_meeting:
        raise AssertionError(
            f"{artist_id} 首次周会应为 {expected_meeting}，实际 {getattr(meeting, 'event_id', None)}"
        )
    chain.append(meeting.event_id)
    apply_flags(flags, meeting.flag_changes)

    if flags.get("meeting.first_session_done") is not True:
        raise AssertionError(f"{artist_id} 首次周会后应设置 meeting.first_session_done")

    return chain


def check_directory_layout() -> None:
    for artist_id in SIGN_IDS:
        sign_path = EVENTS_DIR / "main/artists" / artist_id / Path(SIGN_IDS[artist_id].split("_")[-2] + ".tres")
        # verify canonical paths exist
        folder = EVENTS_DIR / "main/artists" / artist_id
        if not folder.is_dir():
            raise AssertionError(f"缺少目录 {folder}")
        tres_files = list(folder.glob("*.tres"))
        if len(tres_files) < 2:
            raise AssertionError(f"{folder} 应至少 2 则 .tres")


def check_ui_and_wiring() -> None:
    pick = _read(OPENING_PICK)
    for label in ACTION_LABELS:
        if label not in pick:
            raise AssertionError(f"OpeningArtistPickDialog 缺少行动文案：{label}")
    if "OPENING_ACTIONS" not in pick:
        raise AssertionError("OpeningArtistPickDialog 应使用 OPENING_ACTIONS")
    if "get_portrait" in pick or "選擇首位藝人" in pick:
        raise AssertionError("OpeningArtistPickDialog 不应再显示艺人立绘/姓名卡片")

    root = _read(GAME_ROOT)
    for token in (
        "_start_opening_sign_story",
        "_play_artist_003_opening_preface",
        "_play_artist_003_knock_bridge",
        "play_artist_003_tv_preface_bridge",
    ):
        if token not in root and token not in _read(STORY_TRANSITION):
            raise AssertionError(f"缺少开局接线：{token}")

    trigger = _read(TRIGGER_MGR)
    if "primary_artist_id if is_first_meeting else" not in trigger:
        raise AssertionError("StoryTriggerManager 首次周会应传 primary_artist_id 作 owner 过滤")


def check_legacy_removed(events: dict[str, StoryEvent]) -> None:
    legacy = (
        "story_sign_artist_001_first_meeting",
        "story_sign_artist_002_first_meeting",
        "story_sign_artist_003_first_meeting",
        "story_meeting_first_session_01",
        "story_main_artist_003_day1_office_01",
        "story_meeting_artist_003_welcome_cake_01",
    )
    for eid in legacy:
        if eid in events:
            raise AssertionError(f"旧 event_id 仍存在：{eid}")
    old_paths = [
        EVENTS_DIR / "main/artist_001",
        EVENTS_DIR / "main/artist_003/01_day1_office.tres",
        EVENTS_DIR / "meeting/00_first_session.tres",
    ]
    for p in old_paths:
        if p.exists():
            raise AssertionError(f"旧路径未清理：{p}")


def run_twenty_rounds(events: dict[str, StoryEvent]) -> None:
    artists = ("artist_001", "artist_002", "artist_003")
    for i in range(1, ROUNDS + 1):
        artist_id = artists[(i - 1) % len(artists)]
        chain = simulate_opening_chain(events, artist_id)
        print(f"  [PASS] 第 {i:02d} 轮 {artist_id}：{' → '.join(chain)}")


def main() -> None:
    print("=== opening_flow_sandbox (20 轮) ===")
    check_directory_layout()
    print("  [PASS] main/artists/ 目录结构")
    check_ui_and_wiring()
    print("  [PASS] 行动三选一 UI 与接线")
    events = load_story_events()
    check_legacy_removed(events)
    print("  [PASS] 旧 event_id / 路径已移除")
    for artist_id, eid in SIGN_IDS.items():
        if eid not in events:
            raise AssertionError(f"缺少 {eid}")
    for artist_id, eid in MEETING_IDS.items():
        if eid not in events:
            raise AssertionError(f"缺少 {eid}")
    print(f"  [PASS] 6 则主线 event 已载入（共 {len(events)} 则）")
    run_twenty_rounds(events)
    print(f"opening_flow_sandbox：{ROUNDS} 轮全部通过。")


if __name__ == "__main__":
    try:
        main()
    except AssertionError as exc:
        print(f"  [FAIL] {exc}")
        sys.exit(1)
