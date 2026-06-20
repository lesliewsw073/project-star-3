#!/usr/bin/env python3
"""一键运行全部 Python 沙盘。"""

from __future__ import annotations

import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent
SANDBOXES = [
    "save_v1_sandbox.py",
    "save_slots_sandbox.py",
    "character_assets_sandbox.py",
    "id_alignment_sandbox.py",
    "job_facility_alignment_sandbox.py",
    "day_cycle_sandbox.py",
    "follow_plan_sandbox.py",
    "schedule_vacation_sandbox.py",
    "schedule_flow_sandbox.py",
    "follow_story_sandbox.py",
    "maphub_ui_sandbox.py",
    "artist_profile_sandbox.py",
    "agency_database_sandbox.py",
    "character_database_sandbox.py",
    "npc_database_sandbox.py",
    "story_event_sandbox.py",
    "opening_flow_sandbox.py",
    "company_standing_sandbox.py",
    "item_system_sandbox.py",
    "job_day_evaluator_sandbox.py",
    "job_invite_ui_sandbox.py",
    "content_tier_sandbox.py",
    "news_system_sandbox.py",
    "stress_integration_sandbox.py",
]


def main() -> None:
    failed: list[str] = []
    print("=== 运行全部沙盘 ===\n")
    for name in SANDBOXES:
        path = ROOT / name
        print(f"--- {name} ---")
        result = subprocess.run([sys.executable, str(path)], capture_output=True, text=True)
        print(result.stdout, end="")
        if result.stderr:
            print(result.stderr, file=sys.stderr)
        if result.returncode != 0:
            failed.append(name)
        print()
    if failed:
        print(f"失败：{', '.join(failed)}")
        sys.exit(1)
    print("全部沙盘通过。")


if __name__ == "__main__":
    main()
