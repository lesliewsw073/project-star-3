#!/usr/bin/env python3
"""通告／課程／打工／設施／公司交叉引用對齊檢查。"""

from __future__ import annotations

import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
JOBS_DIR = ROOT / "data/jobs"
FACILITIES_DIR = ROOT / "data/facilities"
LOCATIONS_DIR = ROOT / "data/locations"
COURSES_DIR = ROOT / "data/courses"
GIGS_DIR = ROOT / "data/gigs"
STORY_DIR = ROOT / "data/story_events"
COMP_DB = ROOT / "scripts/autoload/CompanyDatabase.gd"
COURSE_MGR = ROOT / "scripts/autoload/CourseManager.gd"


def _read(path: Path) -> str:
    return path.read_text(encoding="utf-8")


def _field(text: str, name: str) -> str:
    m = re.search(rf'^{name}\s*=\s*"(.*)"', text, re.M)
    return m.group(1) if m else ""


def _parse_companies() -> dict[str, dict]:
    text = _read(COMP_DB)
    out: dict[str, dict] = {}
    for m in re.finditer(
        r'"((?:comp_[^"]+))":\s*\{[^}]*"location_id":\s*"([^"]+)"',
        text,
        re.S,
    ):
        out[m.group(1)] = {"location_id": m.group(2)}
    return out


def _load_facilities() -> dict[str, dict]:
    facilities: dict[str, dict] = {}
    for path in sorted(FACILITIES_DIR.rglob("*.tres")):
        text = _read(path)
        fid = _field(text, "facility_id")
        if not fid:
            continue
        facilities[fid] = {
            "path": path,
            "linked_company_id": _field(text, "linked_company_id"),
            "screen_hint": _screen_from_path(path),
        }
    return facilities


def _screen_from_path(path: Path) -> str:
    m = re.search(r"screen(\d+)_", path.as_posix())
    if not m:
        return ""
    return f"screen_{m.group(1)}"


def _load_location_screens() -> dict[str, str]:
    """facility_id -> location_id（由 location tres 引用推導）。"""
    mapping: dict[str, str] = {}
    for loc_path in sorted(LOCATIONS_DIR.glob("*.tres")):
        text = _read(loc_path)
        loc_id = _field(text, "location_id")
        if not loc_id:
            continue
        for rel in re.findall(r'path="(res://data/facilities/[^"]+)"', text):
            fac_path = ROOT / rel.replace("res://", "")
            if fac_path.is_file():
                fac_text = _read(fac_path)
                fid = _field(fac_text, "facility_id")
                if fid:
                    mapping[fid] = loc_id
    return mapping


def check_course_initial_unlock() -> None:
    text = _read(COURSE_MGR)
    if "INITIAL_UNLOCKED_COURSE_IDS" not in text:
        raise AssertionError("CourseManager 缺少 INITIAL_UNLOCKED_COURSE_IDS")
    if "course_acting_basic_01" not in text:
        raise AssertionError("INITIAL_UNLOCKED_COURSE_IDS 應含 course_acting_basic_01")
    if "_reset_initial_unlocks" not in text:
        raise AssertionError("CourseManager 應在 _ready / import 後重置初始解鎖")


def check_course_geo_binding() -> None:
    path = COURSES_DIR / "course_acting_basic_01.tres"
    text = _read(path)
    if _field(text, "unlock_location_id") != "screen_3":
        raise AssertionError("course_acting_basic_01 unlock_location_id 應為 screen_3")
    if _field(text, "unlock_facility_id") != "fac_training_base":
        raise AssertionError("course_acting_basic_01 unlock_facility_id 應為 fac_training_base")


def check_facility_id_naming(facilities: dict[str, dict]) -> None:
    for fid, info in facilities.items():
        if fid.startswith("fac_"):
            continue
        if fid in ("fac_home",):
            continue
        raise AssertionError(f"設施 id 應 fac_* 前綴：{fid}（{info['path']}）")


def check_jobs_publisher_facility_alignment(
    facilities: dict[str, dict],
    fac_to_location: dict[str, str],
    companies: dict[str, dict],
) -> None:
    for path in sorted(JOBS_DIR.rglob("*.tres")):
        text = _read(path)
        job_id = _field(text, "job_id")
        if not job_id:
            continue
        publisher = _field(text, "target_company_id")
        unlock_fac = _field(text, "unlock_facility_id")
        unlock_loc = _field(text, "unlock_location_id")
        if not unlock_fac:
            raise AssertionError(f"{path.name} 缺 unlock_facility_id")
        if unlock_fac not in facilities:
            raise AssertionError(f"{job_id} 引用未知設施 {unlock_fac}")
        fac = facilities[unlock_fac]
        linked = fac["linked_company_id"]
        if linked and publisher and linked != publisher:
            raise AssertionError(
                f"{job_id}: target_company_id={publisher} ≠ 設施 {unlock_fac} 的 comp={linked}"
            )
        if publisher and publisher not in companies:
            raise AssertionError(f"{job_id} 未知 target_company_id={publisher}")
        expected_loc = fac_to_location.get(unlock_fac, fac.get("screen_hint", ""))
        if unlock_loc and expected_loc and unlock_loc != expected_loc:
            raise AssertionError(
                f"{job_id}: unlock_location_id={unlock_loc} ≠ 設施所在屏 {expected_loc}"
            )
        if publisher and publisher in companies:
            comp_loc = companies[publisher]["location_id"]
            if comp_loc.startswith("screen_") and unlock_loc and comp_loc != unlock_loc:
                raise AssertionError(
                    f"{job_id}: 公司 {publisher} location={comp_loc} ≠ job unlock_location={unlock_loc}"
                )


def check_story_task_signatures() -> None:
    gig_ids = set()
    for p in GIGS_DIR.glob("*.tres"):
        gid = _field(_read(p), "gig_id")
        if gid:
            gig_ids.add(gid)
    job_ids = set()
    for p in JOBS_DIR.rglob("*.tres"):
        jid = _field(_read(p), "job_id")
        if jid:
            job_ids.add(jid)

    for path in sorted(STORY_DIR.rglob("*.tres")):
        text = _read(path)
        sig = _field(text, "task_signature")
        if not sig:
            continue
        if sig.startswith("gig:"):
            gid = sig.split(":", 1)[1]
            if gid not in gig_ids:
                raise AssertionError(f"{path.name} 未知 gig task_signature={sig}")
        elif sig.startswith("job:"):
            jid = sig.split(":", 1)[1]
            if jid not in job_ids:
                raise AssertionError(f"{path.name} 未知 job task_signature={sig}")


def check_meeting_ui_uses_unlocked() -> None:
    text = _read(ROOT / "scripts/controllers/GameRootController.gd")
    if "CourseManager.get_all_courses()" in text:
        raise AssertionError("週會排程仍使用 get_all_courses()，應改 get_unlocked_courses()")
    if "GigManager.get_all_gigs()" in text:
        raise AssertionError("週會排程仍使用 get_all_gigs()，應改 get_unlocked_gigs()")


def main() -> None:
    companies = _parse_companies()
    facilities = _load_facilities()
    fac_to_location = _load_location_screens()
    check_course_initial_unlock()
    check_course_geo_binding()
    check_facility_id_naming(facilities)
    check_jobs_publisher_facility_alignment(facilities, fac_to_location, companies)
    check_story_task_signatures()
    check_meeting_ui_uses_unlocked()
    print("job_facility_alignment_sandbox: 全部檢查通過。")


if __name__ == "__main__":
    try:
        main()
    except AssertionError as exc:
        print(f"job_facility_alignment_sandbox: 失敗 — {exc}", file=sys.stderr)
        sys.exit(1)
