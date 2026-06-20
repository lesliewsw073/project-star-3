#!/usr/bin/env python3
"""人物檔案：靜態接線檢查 + 邏輯鏡像壓力測試。"""

from __future__ import annotations

import random
import re
import string
import sys
import time
from dataclasses import dataclass, field
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
ARTISTS_DIR = ROOT / "data" / "artists"
PROFILE_SCRIPT = ROOT / "scripts" / "resources" / "ArtistProfileResource.gd"
DISPLAY_SCRIPT = ROOT / "scripts/ui/ArtistProfileDisplay.gd"
RESOLVER_SCRIPT = ROOT / "scripts/autoload" / "DialogueVariableResolver.gd"
ARTIST_RESOURCE_SCRIPT = ROOT / "scripts/resources/Artist_Resource.gd"
GAME_ROOT = ROOT / "scripts/controllers/GameRootController.gd"
OPENING_PICK = ROOT / "scripts/ui/OpeningArtistPickDialog.gd"
SIGN_DIALOG = ROOT / "scripts/ui/ArtistSignProfileDialog.gd"
ARTIST_MANAGER = ROOT / "scripts/autoload/ArtistManager.gd"

REQUIRED_PROFILE_FIELDS = [
    "age",
    "height_cm",
    "weight_kg",
    "bust_cm",
    "waist_cm",
    "hip_cm",
    "likes",
    "dislikes",
    "development_goal",
]

REQUIRED_DIALOGUE_KEYS = [
    "artist_age",
    "artist_height",
    "artist_weight",
    "artist_measurements",
    "artist_bwh",
    "artist_likes",
    "artist_dislikes",
    "artist_goal",
    "artist_development_goal",
    "artist_name",
]

SUB_RESOURCE_RE = re.compile(
    r'\[sub_resource type="Resource" id="([^"]+)"\]\s*\n'
    r'(?:[^\[]*?)'
    r'script = ExtResource\("[^"]+"\)\s*\n'
    r'((?:[^\[]*?))(?=\n\[|\Z)',
    re.DOTALL,
)
STRING_FIELD_RE = re.compile(r'^(\w+)\s*=\s*"(.*)"\s*$', re.MULTILINE)
INT_FIELD_RE = re.compile(r'^(\w+)\s*=\s*(-?\d+)\s*$', re.MULTILINE)


@dataclass
class Profile:
    age: int = 0
    height_cm: int = 0
    weight_kg: int = 0
    bust_cm: int = 0
    waist_cm: int = 0
    hip_cm: int = 0
    likes: str = ""
    dislikes: str = ""
    development_goal: str = ""
    artist_name: str = ""


@dataclass
class ArtistTres:
    path: Path
    artist_id: str
    artist_name: str
    profile: Profile | None
    has_core_stats: bool


def _read(path: Path) -> str:
    return path.read_text(encoding="utf-8")


def parse_profile_block(block: str) -> Profile:
    profile = Profile()
    for key, value in INT_FIELD_RE.findall(block):
        if hasattr(profile, key):
            setattr(profile, key, int(value))
    for key, value in STRING_FIELD_RE.findall(block):
        if hasattr(profile, key):
            setattr(profile, key, value)
    return profile


def parse_artist_tres(path: Path) -> ArtistTres:
    text = _read(path)
    artist_id = ""
    artist_name = ""
    profile_ref = ""
    profile: Profile | None = None

    m_id = re.search(r'^artist_id\s*=\s*"(.*)"\s*$', text, re.MULTILINE)
    if m_id:
        artist_id = m_id.group(1)
    m_name = re.search(r'^artist_name\s*=\s*"(.*)"\s*$', text, re.MULTILINE)
    if m_name:
        artist_name = m_name.group(1)
    m_ref = re.search(r"character_profile\s*=\s*SubResource\(\"([^\"]+)\"\)", text)
    if m_ref:
        profile_ref = m_ref.group(1)

    profiles_by_id: dict[str, Profile] = {}
    for sub_id, body in SUB_RESOURCE_RE.findall(text):
        if "ArtistProfileResource" in text or any(f"{f} =" in body for f in REQUIRED_PROFILE_FIELDS):
            profiles_by_id[sub_id] = parse_profile_block(body)

    if profile_ref and profile_ref in profiles_by_id:
        profile = profiles_by_id[profile_ref]
        profile.artist_name = artist_name

    core_stats = any(
        re.search(rf"^{stat}\s*=\s*\d+", text, re.MULTILINE)
        for stat in ("empathy", "acting", "singing", "fame")
    )
    return ArtistTres(path=path, artist_id=artist_id, artist_name=artist_name, profile=profile, has_core_stats=core_stats)


# ---------------------------------------------------------------------------
# Python 鏡像：ArtistProfileResource / ArtistProfileDisplay / Dialogue 解析
# ---------------------------------------------------------------------------

def normalize_text(value: str) -> str:
    text = value.strip()
    if text == "":
        return "—"
    return text.replace("\n", " ")


def format_age(age: int) -> str:
    return "—" if age <= 0 else f"{age} 歲"


def format_height(height_cm: int) -> str:
    return "—" if height_cm <= 0 else f"{height_cm} cm"


def format_weight(weight_kg: int) -> str:
    return "—" if weight_kg <= 0 else f"{weight_kg} kg"


def format_measurements(profile: Profile) -> str:
    if profile.bust_cm <= 0 and profile.waist_cm <= 0 and profile.hip_cm <= 0:
        return "—"
    return f"{profile.bust_cm} / {profile.waist_cm} / {profile.hip_cm}"


def has_any_content(profile: Profile) -> bool:
    return (
        profile.age > 0
        or profile.height_cm > 0
        or profile.weight_kg > 0
        or profile.bust_cm > 0
        or profile.waist_cm > 0
        or profile.hip_cm > 0
        or profile.likes.strip() != ""
        or profile.dislikes.strip() != ""
        or profile.development_goal.strip() != ""
    )


def get_summary_lines(profile: Profile) -> list[str]:
    lines: list[str] = []
    if profile.age > 0:
        lines.append(f"年齡：{format_age(profile.age)}")
    if profile.height_cm > 0:
        lines.append(f"身高：{format_height(profile.height_cm)}")
    if profile.weight_kg > 0:
        lines.append(f"體重：{format_weight(profile.weight_kg)}")
    if profile.bust_cm > 0 or profile.waist_cm > 0 or profile.hip_cm > 0:
        lines.append(f"三圍：{format_measurements(profile)}")
    likes = normalize_text(profile.likes)
    if likes != "—":
        lines.append(f"喜歡：{likes}")
    dislikes = normalize_text(profile.dislikes)
    if dislikes != "—":
        lines.append(f"討厭：{dislikes}")
    goal = normalize_text(profile.development_goal)
    if goal != "—":
        lines.append(f"目標：{goal}")
    return lines


def get_dialogue_replacements(profile: Profile) -> dict[str, str]:
    return {
        "artist_age": format_age(profile.age),
        "artist_height": format_height(profile.height_cm),
        "artist_weight": format_weight(profile.weight_kg),
        "artist_measurements": format_measurements(profile),
        "artist_bwh": format_measurements(profile),
        "artist_likes": normalize_text(profile.likes),
        "artist_dislikes": normalize_text(profile.dislikes),
        "artist_goal": normalize_text(profile.development_goal),
        "artist_development_goal": normalize_text(profile.development_goal),
    }


def build_detail_multiline(profile: Profile | None) -> str:
    if profile is None or not has_any_content(profile):
        return "（檔案尚未填寫）"
    lines = get_summary_lines(profile)
    return "（檔案尚未填寫）" if not lines else "\n".join(lines)


def build_compact_line(profile: Profile | None) -> str:
    if profile is None or not has_any_content(profile):
        return ""
    parts: list[str] = []
    if profile.age > 0:
        parts.append(format_age(profile.age))
    if profile.height_cm > 0:
        parts.append(format_height(profile.height_cm))
    if profile.weight_kg > 0:
        parts.append(format_weight(profile.weight_kg))
    if profile.bust_cm > 0 or profile.waist_cm > 0 or profile.hip_cm > 0:
        parts.append(f"三圍 {format_measurements(profile)}")
    likes = normalize_text(profile.likes)
    if likes != "—":
        parts.append(f"喜歡：{likes}")
    goal = normalize_text(profile.development_goal)
    if goal != "—":
        parts.append(f"目標：{goal}")
    return " · ".join(parts)


def build_roster_sidebar_text(artists: list[ArtistTres], signed_ids: list[str]) -> str:
    if not signed_ids:
        return ""
    blocks: list[str] = []
    by_id = {a.artist_id: a for a in artists}
    for artist_id in signed_ids:
        artist = by_id.get(artist_id)
        if artist is None or artist.profile is None:
            continue
        compact = build_compact_line(artist.profile)
        if compact:
            blocks.append(f"・{artist.artist_name}：{compact}")
    return "\n".join(blocks)


def resolve_dialogue(raw: str, profile: Profile | None, artist_name: str) -> str:
    replacements = {key: "—" for key in REQUIRED_DIALOGUE_KEYS}
    replacements["artist_name"] = artist_name
    if profile is not None:
        replacements.update(get_dialogue_replacements(profile))
    resolved = raw
    for key, value in replacements.items():
        resolved = resolved.replace(f"{{{key}}}", value)
    return resolved


def random_text(rng: random.Random, max_len: int = 80) -> str:
    chars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789，。！？、"
    length = rng.randint(0, max_len)
    if length == 0:
        return ""
    if rng.random() < 0.15:
        return "\n".join(
            "".join(rng.choice(chars) for _ in range(rng.randint(1, 20)))
            for _ in range(rng.randint(1, 4))
        )
    return "".join(rng.choice(chars) for _ in range(length))


def random_profile(rng: random.Random) -> Profile:
    return Profile(
        age=rng.randint(0, 120),
        height_cm=rng.randint(0, 250),
        weight_kg=rng.randint(0, 200),
        bust_cm=rng.randint(0, 200),
        waist_cm=rng.randint(0, 200),
        hip_cm=rng.randint(0, 200),
        likes=random_text(rng),
        dislikes=random_text(rng),
        development_goal=random_text(rng, 120),
    )


# ---------------------------------------------------------------------------
# 靜態檢查
# ---------------------------------------------------------------------------

def check_profile_script() -> None:
    text = _read(PROFILE_SCRIPT)
    for field in REQUIRED_PROFILE_FIELDS:
        if f"var {field}" not in text:
            raise AssertionError(f"ArtistProfileResource 缺少欄位：{field}")
    if "get_dialogue_replacements" not in text:
        raise AssertionError("ArtistProfileResource 缺少 get_dialogue_replacements()")


def check_display_script() -> None:
    text = _read(DISPLAY_SCRIPT)
    for fn in (
        "build_detail_multiline",
        "build_detail_multiline_for_id",
        "build_compact_line",
        "build_roster_sidebar_text",
        "populate_labels",
    ):
        if f"func {fn}" not in text:
            raise AssertionError(f"ArtistProfileDisplay 缺少 {fn}()")


def check_artist_resource_separation() -> None:
    text = _read(ARTIST_RESOURCE_SCRIPT)
    if "character_profile: ArtistProfileResource" not in text:
        raise AssertionError("ArtistResource 未宣告 character_profile")
    if "get_character_profile" not in text:
        raise AssertionError("ArtistResource 缺少 get_character_profile()")
    # 能力值與檔案應分組
    if text.find("@export_group(\"人物檔案\")") > text.find("@export_group(\"核心數值\")"):
        raise AssertionError("人物檔案 export 應在核心數值之前且分組獨立")


def check_dialogue_resolver() -> None:
    text = _read(RESOLVER_SCRIPT)
    for key in REQUIRED_DIALOGUE_KEYS:
        if key not in text:
            raise AssertionError(f"DialogueVariableResolver 未處理 {{{key}}}")
    if "_merge_artist_profile_replacements" not in text:
        raise AssertionError("DialogueVariableResolver 缺少 profile 合併函式")


def check_ui_wiring() -> None:
    game_root = _read(GAME_ROOT)
    required_symbols = [
        "_roster_profile_label",
        "_job_artist_profile_label",
        "_meeting_profile_label",
        "_artist_sign_profile_dialog",
        "_prompt_artist_sign_profile",
        "ArtistProfileDisplay.build_roster_sidebar_text",
        "ArtistProfileDisplay.build_detail_multiline_for_id",
    ]
    for sym in required_symbols:
        if sym not in game_root:
            raise AssertionError(f"GameRootController 缺少 {sym}")

    opening = _read(OPENING_PICK)
    if "OPENING_ACTIONS" not in opening:
        raise AssertionError("OpeningArtistPickDialog 应使用 OPENING_ACTIONS 行动三选一")
    if "下樓透透氣" not in opening or "打開電視看看" not in opening:
        raise AssertionError("OpeningArtistPickDialog 缺少定案行动文案")
    if "ArtistSignProfileDialog" in opening:
        raise AssertionError("开局三选一不应再挂载 ArtistSignProfileDialog")

    sign_dialog = _read(SIGN_DIALOG)
    if "ArtistProfileDisplay.populate_labels" not in sign_dialog:
        raise AssertionError("ArtistSignProfileDialog 未使用 populate_labels")

    # 通告中心簽約應走 profile 確認，不直接 sign_artist
    sign_fn = re.search(
        r"func _on_job_center_sign_artist_pressed\(artist_id: String\) -> void:(.*?)(?=\nfunc |\Z)",
        game_root,
        re.DOTALL,
    )
    if sign_fn is None:
        raise AssertionError("找不到 _on_job_center_sign_artist_pressed")
    body = sign_fn.group(1)
    if "_prompt_artist_sign_profile" not in body:
        raise AssertionError("通告中心簽約未走 _prompt_artist_sign_profile")
    if "ArtistManager.sign_artist" in body:
        raise AssertionError("通告中心簽約仍直接呼叫 sign_artist，應先開檔案面板")

    # 會議 refresh 順序：is_artist 先於 profile label
    refresh_fn = re.search(
        r"func _refresh_meeting_detail\(\) -> void:(.*?)(?=\nfunc |\Z)",
        game_root,
        re.DOTALL,
    )
    if refresh_fn is None:
        raise AssertionError("找不到 _refresh_meeting_detail")
    refresh_body = refresh_fn.group(1)
    is_artist_pos = refresh_body.find("var is_artist")
    profile_pos = refresh_body.find("_meeting_profile_label")
    if is_artist_pos < 0 or profile_pos < 0 or is_artist_pos > profile_pos:
        raise AssertionError("_refresh_meeting_detail：is_artist 須在 _meeting_profile_label 之前宣告")


def check_artist_manager_api() -> None:
    text = _read(ARTIST_MANAGER)
    if "func get_artist_profile" not in text:
        raise AssertionError("ArtistManager 缺少 get_artist_profile()")


def check_artist_tres_files(artists: list[ArtistTres]) -> None:
    if len(artists) < 16:
        raise AssertionError(f"應至少 16 位藝人 .tres，實際 {len(artists)}")
    profile_ready = [a for a in artists if a.profile is not None and has_any_content(a.profile)]
    if len(profile_ready) < 3:
        raise AssertionError("開局三選一（001-003）應有 character_profile")
    for artist in profile_ready:
        detail = build_detail_multiline(artist.profile)
        if detail == "（檔案尚未填寫）":
            raise AssertionError(f"{artist.path.name} 無法組裝檔案文案")


# ---------------------------------------------------------------------------
# 壓力測試
# ---------------------------------------------------------------------------

def stress_random_profiles(rounds: int, seed: int) -> tuple[int, float]:
    rng = random.Random(seed)
    start = time.perf_counter()
    empty_count = 0
    for _ in range(rounds):
        profile = random_profile(rng)
        _ = has_any_content(profile)
        lines = get_summary_lines(profile)
        detail = build_detail_multiline(profile)
        compact = build_compact_line(profile)
        reps = get_dialogue_replacements(profile)

        if not has_any_content(profile):
            assert detail == "（檔案尚未填寫）", "空檔案應回退占位文案"
            assert compact == "", "空檔案 compact 應為空"
            empty_count += 1
        else:
            assert detail != "（檔案尚未填寫）", "有內容時不應占位"
            assert len(lines) >= 1, "有內容時 summary 至少一行"

        for key in REQUIRED_DIALOGUE_KEYS:
            if key == "artist_name":
                continue
            assert key in reps or key in {"artist_name"}, f"缺少 dialogue key {key}"

        template = (
            "我是{artist_name}，{artist_age}，身高{artist_height}，"
            "三圍{artist_bwh}，喜歡{artist_likes}，討厭{artist_dislikes}，目標{artist_goal}"
        )
        resolved = resolve_dialogue(template, profile, "測試藝人")
        assert "{" not in resolved or "}" not in resolved, f"未完全替換：{resolved[:80]}"

    elapsed = time.perf_counter() - start
    return empty_count, elapsed


def stress_dialogue_templates(rounds: int, seed: int) -> float:
    rng = random.Random(seed + 1)
    templates = [
        "{artist_likes}",
        "{artist_age}歲的{artist_name}",
        "三圍{artist_measurements}／{artist_bwh}",
        "{artist_dislikes}と{artist_goal}",
        "{" + "artist_height" + "}",
    ]
    start = time.perf_counter()
    for _ in range(rounds):
        profile = random_profile(rng)
        tpl = rng.choice(templates)
        resolved = resolve_dialogue(tpl, profile, rng.choice(["一号", "二号", "三号", ""]))
        assert isinstance(resolved, str)
    return time.perf_counter() - start


def stress_roster_sidebar(rounds: int, artists: list[ArtistTres], seed: int) -> float:
    rng = random.Random(seed + 2)
    ids = [a.artist_id for a in artists]
    start = time.perf_counter()
    for _ in range(rounds):
        signed = rng.sample(ids, k=rng.randint(0, len(ids)))
        text = build_roster_sidebar_text(artists, signed)
        if not signed:
            assert text == ""
        else:
            for artist_id in signed:
                artist = next(a for a in artists if a.artist_id == artist_id)
                if build_compact_line(artist.profile):
                    assert artist.artist_name in text
    return time.perf_counter() - start


def stress_edge_cases() -> None:
    cases: list[tuple[str, Profile, str | None]] = [
        ("全零", Profile(), "（檔案尚未填寫）"),
        ("僅年齡", Profile(age=18), None),
        ("僅空白文字", Profile(likes="   ", dislikes="\n"), "（檔案尚未填寫）"),
        ("換行喜好", Profile(likes="A\nB\nC"), None),
        ("三圍部分零", Profile(bust_cm=90, waist_cm=0, hip_cm=88), None),
        ("極長目標", Profile(development_goal="X" * 5000), None),
        ("特殊符號", Profile(likes='引號"與{artist_age}混用'), None),
    ]
    for name, profile, expected_detail in cases:
        detail = build_detail_multiline(profile)
        if expected_detail is not None:
            assert detail == expected_detail, f"{name}: detail={detail!r}"
        reps = get_dialogue_replacements(profile)
        tpl = "喜歡{artist_likes}，目標{artist_goal}"
        resolved = resolve_dialogue(tpl, profile, "邊界")
        assert "{artist_likes}" not in resolved
        assert "{artist_goal}" not in resolved


def stress_real_tres_roundtrip(artists: list[ArtistTres], rounds: int) -> float:
    profile_artists = [a for a in artists if a.profile is not None and has_any_content(a.profile)]
    if not profile_artists:
        return 0.0
    start = time.perf_counter()
    for i in range(rounds):
        artist = profile_artists[i % len(profile_artists)]
        profile = artist.profile
        assert profile is not None
        detail = build_detail_multiline(profile)
        compact = build_compact_line(profile)
        assert detail != "（檔案尚未填寫）"
        assert compact != ""
        tpl = (
            "{artist_name}：{artist_age}｜{artist_height}｜{artist_weight}｜"
            "{artist_measurements}｜喜歡{artist_likes}｜討厭{artist_dislikes}｜{artist_development_goal}"
        )
        resolved = resolve_dialogue(tpl, profile, artist.artist_name)
        assert artist.artist_name in resolved
        assert "{" not in resolved
    return time.perf_counter() - start


def run_round(name: str, fn) -> None:
    fn()
    print(f"  [PASS] {name}")


def main() -> None:
    print("=== artist_profile_sandbox（靜態 + 壓力）===\n")

    artists = [parse_artist_tres(p) for p in sorted(ARTISTS_DIR.glob("**/artist_*.tres"))]

    print("-- 靜態接線 --")
    run_round("ArtistProfileResource 欄位", check_profile_script)
    run_round("ArtistProfileDisplay API", check_display_script)
    run_round("ArtistResource 分離結構", check_artist_resource_separation)
    run_round("DialogueVariableResolver 變數", check_dialogue_resolver)
    run_round("ArtistManager get_artist_profile", check_artist_manager_api)
    run_round("UI / 簽約流程接線", check_ui_wiring)
    run_round(f"藝人 .tres（{len(artists)} 份）", lambda: check_artist_tres_files(artists))

    print("\n-- 邊界案例 --")
    run_round("空檔／換行／特殊字元", stress_edge_cases)

    print("\n-- 壓力測試 --")
    empty_count, t1 = stress_random_profiles(8000, seed=20260618)
    print(f"  [PASS] 隨機 profile ×8000（空檔 {empty_count} 筆，{t1:.3f}s）")

    t2 = stress_dialogue_templates(3000, seed=20260618)
    print(f"  [PASS] 對話模板替換 ×3000（{t2:.3f}s）")

    t3 = stress_roster_sidebar(2000, artists, seed=20260618)
    print(f"  [PASS] 左欄 roster 摘要 ×2000（{t3:.3f}s）")

    t4 = stress_real_tres_roundtrip(artists, 600)
    print(f"  [PASS] 真實 .tres 往返 ×600（{t4:.3f}s）")

    # 簽約面板文案長度 sanity
    for artist in artists:
        if artist.profile is None or not has_any_content(artist.profile):
            continue
        detail = build_detail_multiline(artist.profile)
        assert 3 <= detail.count("\n") + 1 <= 10, f"{artist.artist_id} 摘要行數異常"
    print("  [PASS] 已填檔案藝人摘要行數合理")

    print("\nartist_profile_sandbox 全部通過。")


if __name__ == "__main__":
    try:
        main()
    except AssertionError as exc:
        print(f"\n失敗：{exc}", file=sys.stderr)
        sys.exit(1)
