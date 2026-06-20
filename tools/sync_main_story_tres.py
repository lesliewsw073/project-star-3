#!/usr/bin/env python3
"""从 docs/writing 主线 md 生成 data/story_events/main/artists/*.tres。"""

from __future__ import annotations

import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
WRITING = ROOT / "docs/writing/02_Story_Events/1_Main_Story/Artists"
OUT = ROOT / "data/story_events/main/artists"

CHANNEL_MAP = {"sign": 1, "calendar": 2, "meeting": 3}
ARC_MAP = {"main_once": 1, "first_meeting": 2, "flavor_repeat": 3}
CANONICAL_ARTISTS = {"artist_003"}


def _read(path: Path) -> str:
    return path.read_text(encoding="utf-8")


def _split_frontmatter(text: str) -> tuple[str, str]:
    m = re.match(r"^---\n(.*?)\n---\n(.*)$", text, re.S)
    if not m:
        return "", text
    return m.group(1), m.group(2)


def _parse_yaml_block(block: str, key: str) -> dict[str, object]:
    m = re.search(rf"^{key}:\n((?:  .+\n)+)", block, re.M)
    if not m:
        return {}
    out: dict[str, object] = {}
    for line in m.group(1).splitlines():
        kv = re.match(r"\s+(\S+):\s*(.+)", line)
        if not kv:
            continue
        val = kv.group(2).strip()
        if val in ("true", "false"):
            out[kv.group(1)] = val == "true"
        else:
            out[kv.group(1)] = val
    return out


def _parse_scalar(block: str, key: str, default: object = "") -> object:
    m = re.search(rf"^{key}:\s*(.+)$", block, re.M)
    if not m:
        return default
    val = m.group(1).strip()
    if val in ("true", "false"):
        return val == "true"
    return val


def _parse_dialogue(body: str) -> list[tuple[str, str]]:
    lines: list[tuple[str, str]] = []
    for raw in body.splitlines():
        line = raw.strip()
        m = re.match(r"^\*\*([^*]+)\*\*:\s*(.+)$", line)
        if not m:
            continue
        speaker = m.group(1).strip()
        text_part = m.group(2).strip()
        if text_part.startswith("*("):
            continue
        if text_part.startswith('"') and text_part.endswith('"'):
            text_part = text_part[1:-1]
        if speaker in ("旁白", "narrator"):
            speaker_id = "narrator"
        elif speaker.startswith("【"):
            speaker_id = "secretary"
        else:
            speaker_id = speaker
        if text_part:
            lines.append((speaker_id, text_part))
    return lines


def _dict_to_tres(d: dict[str, object]) -> str:
    if not d:
        return "{}"
    parts = []
    for k, v in d.items():
        if isinstance(v, bool):
            parts.append(f'"{k}": {"true" if v else "false"}')
        else:
            parts.append(f'"{k}": "{v}"')
    return "{" + ", ".join(parts) + "}"


def _escape_godot_string(s: str) -> str:
    return s.replace("\\", "\\\\").replace('"', '\\"')


def build_tres_from_md(md_path: Path, out_path: Path) -> None:
    text = _read(md_path)
    fm, body = _split_frontmatter(text)
    dialogue = _parse_dialogue(body)
    if not dialogue:
        raise AssertionError(f"{md_path.name} 未解析到对话行")

    event_id = str(_parse_scalar(fm, "event_id"))
    channel_key = str(_parse_scalar(fm, "channel", "sign"))
    story_channel = CHANNEL_MAP[channel_key]
    arc_type = ARC_MAP.get(str(_parse_scalar(fm, "arc_type", "main_once")), 1)
    owner = str(_parse_scalar(fm, "owner"))
    title = str(_parse_scalar(fm, "title", event_id))
    execute_once = bool(_parse_scalar(fm, "execute_once", True))
    cg_id = str(_parse_scalar(fm, "cg_id", "")).strip()
    required = _parse_yaml_block(fm, "required_flags")
    sets = _parse_yaml_block(fm, "sets_flags")
    if channel_key == "meeting":
        sets.setdefault("meeting.first_session_done", True)

    artist_id = owner if owner.startswith("artist_") else ""
    is_test = artist_id not in CANONICAL_ARTISTS
    interaction_type = 3 if channel_key == "meeting" else 2

    line_blocks: list[str] = []
    line_refs: list[str] = []
    for i, (speaker_id, line_text) in enumerate(dialogue, 1):
        line_blocks.append(
            f'[sub_resource type="Resource" id="line_{i}"]\n'
            f'script = ExtResource("2_line")\n'
            f'speaker_id = "{speaker_id}"\n'
            f'text = "{_escape_godot_string(line_text)}"\n'
        )
        line_refs.append(f'SubResource("line_{i}")')

    load_steps = 4 + len(dialogue)
    parts = [
        f'[gd_resource type="Resource" script_class="InteractionEventResource" load_steps={load_steps} format=3]',
        "",
        '[ext_resource type="Script" path="res://scripts/resources/InteractionEventResource.gd" id="1_event"]',
        '[ext_resource type="Script" path="res://scripts/resources/dialogue_line.gd" id="2_line"]',
        '[ext_resource type="Script" path="res://scripts/resources/dialogue_sequence.gd" id="3_seq"]',
        "",
        *line_blocks,
        "",
        '[sub_resource type="Resource" id="dialogue"]',
        'script = ExtResource("3_seq")',
        f'lines = Array[ExtResource("2_line")]([{", ".join(line_refs)}])',
        "",
        "[resource]",
        f"is_test_content = {'true' if is_test else 'false'}",
        'script = ExtResource("1_event")',
        f'event_id = "{event_id}"',
        f'event_title = "{title}"',
        f"interaction_type = {interaction_type}",
        f'character_id = "{artist_id}"',
        f"execute_once = {'true' if execute_once else 'false'}",
        f"arc_type = {arc_type}",
        f'owner = "{owner}"',
        f"story_channel = {story_channel}",
    ]
    if channel_key == "meeting":
        parts.append('meeting_scope = "first"')
    if cg_id:
        parts.append(f'cg_id = "{cg_id}"')
    parts.extend([
        "dialogue = SubResource(\"dialogue\")",
        "blocking = true",
        f"required_flags = {_dict_to_tres(required)}",
        f"flag_changes = {_dict_to_tres(sets)}",
        f"priority = {200 if channel_key == 'meeting' else 100}",
    ])
    out_path.parent.mkdir(parents=True, exist_ok=True)
    out_path.write_text("\n".join(parts) + "\n", encoding="utf-8")


def main() -> None:
    mapping = [
        ("artist_001/00_street_sign_01.md", "artist_001/00_street_sign_01.tres"),
        ("artist_001/01_first_meeting_01.md", "artist_001/01_first_meeting_01.tres"),
        ("artist_002/00_theater_sign_01.md", "artist_002/00_theater_sign_01.tres"),
        ("artist_002/01_first_meeting_01.md", "artist_002/01_first_meeting_01.tres"),
        ("artist_003/00_office_sign_01.md", "artist_003/00_office_sign_01.tres"),
        ("artist_003/01_first_meeting_01.md", "artist_003/01_first_meeting_01.tres"),
    ]
    for md_rel, tres_rel in mapping:
        md_path = WRITING / md_rel
        out_path = OUT / tres_rel
        build_tres_from_md(md_path, out_path)
        print(f"  wrote {out_path.relative_to(ROOT)}")
    print("sync_main_story_tres 完成。")


if __name__ == "__main__":
    try:
        main()
    except (AssertionError, SystemExit) as exc:
        print(f"  [FAIL] {exc}", file=sys.stderr)
        sys.exit(1)
