#!/Users/luke/project-star-3/tools/image_tools/.venv/bin/python
"""List selectable character folders under 图片_ref_star3."""
from __future__ import annotations

import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from character_ref import list_character_dirs  # noqa: E402


def main() -> int:
    dirs = list_character_dirs()
    print(f"selectable: {len(dirs)}")
    print()
    for d in dirs:
        n = len(list(d.glob("*.png")))
        tag = "flat" if any(d.glob("*.png")) and not any(p.is_dir() for p in d.iterdir()) else "folder"
        print(f"  {d.name:28}  {n:4} png  [{tag}]  -> feed_character.py {d.name}")
    print()
    print("aliases: ken | odo | ref_1002_kenj002_mle")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
