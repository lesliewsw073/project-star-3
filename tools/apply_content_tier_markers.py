#!/usr/bin/env python3
"""一次性套用 is_test_content 標記並同步占位顯示名。可重複執行（冪等）。"""

from __future__ import annotations

import re
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
DATA = ROOT / "data"

CANONICAL_EVENT_DIRS = {DATA / "story_events/main/artists/artist_003"}
CANONICAL_ARTIST_IDS = {"artist_003"}
CANONICAL_NPC_IDS = {"secretary"}

DISPLAY_RENAMES = {
    "gig_name": {
        "gig_bar_singer_01.tres": "酒吧駐唱",
    },
    "course_name": {
        "course_acting_basic_01.tres": "影視表演基礎班",
    },
    "vacation_name": {
        "vacation_domestic_spring_01.tres": "近郊溫泉療癒",
    },
    "item_name": {
        "comp_item_meeting_plant_01.tres": "會議室綠植",
        "comp_item_meeting_sofa_02.tres": "會議室真皮沙發",
        "attr_item_energy_drink_01.tres": "能量飲料",
        "attr_item_perfume_01.tres": "精品香水",
        "story_item_old_letter_01.tres": "舊日信件",
        "gift_artist_001_handmade_01.tres": "手作小書籤",
    },
    "event_title": {
        "00_first_meeting_sign.tres": None,  # handled per-dir
        "01_day1_office.tres": None,
        "02_first_sunday_welcome.tres": None,
        "follow_gig_bar_singer_01.tres": "酒吧駐唱後台",
        "follow_gig_bar_parallel.tres": "雙人同台後台",
        "visit_bar_gig_01.tres": "酒吧探望",
        "visit_tv_variety_01.tres": "綜藝錄製探望",
        "meeting/01_weekly_flavor.tres": "週會開場",
        "main/artists/artist_001/00_street_sign_01.tres": "路边弹唱·签约",
        "main/artists/artist_002/00_theater_sign_01.tres": "剧院散场·递合同",
    },
}


def _read(path: Path) -> str:
    return path.read_text(encoding="utf-8")


def _write(path: Path, text: str) -> None:
    path.write_text(text, encoding="utf-8")


def _set_bool_field(text: str, field: str, value: bool) -> str:
    line = f"{field} = {'true' if value else 'false'}"
    pattern = re.compile(rf"^{re.escape(field)} = (true|false)\s*$", re.M)
    if pattern.search(text):
        return pattern.sub(line, text, count=1)
    anchor = re.search(r"^\[resource\]\s*$", text, re.M)
    if anchor is None:
        raise ValueError(f"no [resource] in {field}")
    insert_at = anchor.end()
    return text[:insert_at] + f"\n{line}" + text[insert_at:]


def _set_quoted_field(text: str, field: str, new_value: str) -> str:
    escaped = new_value.replace("\\", "\\\\").replace('"', '\\"')
    line = f'{field} = "{escaped}"'
    pattern = re.compile(rf'^{re.escape(field)} = ".*"$', re.M)
    if not pattern.search(text):
        raise ValueError(f"missing {field}")
    return pattern.sub(line, text, count=1)


def _is_canonical_event(path: Path) -> bool:
    for canon_dir in CANONICAL_EVENT_DIRS:
        try:
            path.relative_to(canon_dir)
            return True
        except ValueError:
            continue
    return False


def _process_tres(path: Path) -> list[str]:
    changes: list[str] = []
    rel = path.relative_to(ROOT)
    text = _read(path)

    is_test = True
    if "artists" in path.parts:
        aid = path.parent.name
        is_test = aid not in CANONICAL_ARTIST_IDS
    elif "rivals" in path.parts:
        is_test = True
    elif "npcs/secretary" in str(path):
        is_test = False
    elif "npcs" in path.parts:
        is_test = True
    elif "jobs/test" in str(path):
        is_test = True
    elif "story_events" in path.parts:
        is_test = not _is_canonical_event(path)
    elif path.name in (
        "gig_bar_singer_01.tres",
        "course_acting_basic_01.tres",
        "vacation_domestic_spring_01.tres",
    ):
        is_test = True
    elif "items" in path.parts:
        is_test = True
    else:
        return changes

    new_text = _set_bool_field(text, "is_test_content", is_test)
    if new_text != text:
        changes.append(f"is_test_content={is_test}")
        text = new_text

    for field, mapping in DISPLAY_RENAMES.items():
        for key, title in mapping.items():
            if key in str(rel) and title:
                m = re.search(rf'^{field} = "(.*)"$', text, re.M)
                if m and m.group(1) != title:
                    text = _set_quoted_field(text, field, title)
                    changes.append(f"{field}→{title}")

    for job_path in DATA.glob("jobs/test/*.tres"):
        pass  # job_name 保持乾淨顯示名，測試身份看 is_test_content

    if path == DATA / "jobs/test/test_job_movie_short_01.tres":
        if "is_test_content = true" not in text:
            pass  # already set above

    _write(path, text)
    return changes


def main() -> None:
    targets: list[Path] = []
    targets.extend(DATA.glob("jobs/test/*.tres"))
    targets.extend(DATA.glob("gigs/*.tres"))
    targets.extend(DATA.glob("courses/*.tres"))
    targets.extend(DATA.glob("vacations/*.tres"))
    targets.extend(DATA.glob("items/**/*.tres"))
    targets.extend(DATA.glob("story_events/**/*.tres"))
    targets.extend(DATA.glob("artists/**/*.tres"))
    targets.extend(DATA.glob("rivals/**/*.tres"))
    targets.extend(DATA.glob("npcs/**/*.tres"))
    # 僅標記 *Resource 主檔，跳過 DialogueSequence 等子資源
    skip_names = {"seq_shopkeeper_intro.tres"}

    total = 0
    for path in sorted(set(targets)):
        if not path.is_file() or path.name in skip_names:
            continue
        ch = _process_tres(path)
        if ch:
            print(f"{path.relative_to(ROOT)}: {', '.join(ch)}")
            total += 1
    print(f"已更新 {total} 個資源檔。")


if __name__ == "__main__":
    main()
