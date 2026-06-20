#!/usr/bin/env python3
"""MapHub / FacilityPanel / DialoguePanel UI 節點路徑沙盘（14 輪）。"""

from __future__ import annotations

import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent

NODE_RE = re.compile(
    r'^\[node name="([^"]+)" type="[^"]+" parent="([^"]*)"\]'
)
DOLLAR_PATH_RE = re.compile(r'\$([A-Za-z_][A-Za-z0-9_/]*)')
NODEPATH_RE = re.compile(r'NodePath\("([^"]+)"\)')


def path_exists(nodes: dict[str, str], rel_path: str) -> bool:
    return rel_path in nodes


def build_node_keys(tscn_path: Path) -> dict[str, str]:
    """Return relative node path -> parent relative path."""
    nodes: dict[str, str] = {}
    for line in tscn_path.read_text(encoding="utf-8").splitlines():
        m = NODE_RE.match(line)
        if not m:
            continue
        name, parent = m.group(1), m.group(2)
        if parent == ".":
            nodes[name] = ""
        else:
            nodes[f"{parent}/{name}"] = parent
    return nodes


def parse_tscn_nodes(tscn_path: Path) -> dict[str, str]:
    return build_node_keys(tscn_path)


def extract_dollar_paths(gd_path: Path) -> list[str]:
    text = gd_path.read_text(encoding="utf-8")
    return sorted(set(DOLLAR_PATH_RE.findall(text)))


def extract_nodepath_exports(tscn_path: Path) -> list[str]:
    paths: list[str] = []
    for line in tscn_path.read_text(encoding="utf-8").splitlines():
        for m in NODEPATH_RE.finditer(line):
            paths.append(m.group(1))
    return paths


def check_gd_paths(scene: Path, script: Path) -> list[str]:
    nodes = parse_tscn_nodes(scene)
    errors: list[str] = []
    for rel in extract_dollar_paths(script):
        if not path_exists(nodes, rel):
            errors.append(f"{script.name}: ${rel} 不存在於 {scene.name}")
    return errors


def check_tscn_nodepaths(scene: Path) -> list[str]:
    nodes = parse_tscn_nodes(scene)
    errors: list[str] = []
    for rel in extract_nodepath_exports(scene):
        if not path_exists(nodes, rel):
            errors.append(f"{scene.name}: NodePath(\"{rel}\") 不存在")
    return errors


def simulate_facility_click(facility_id: str) -> tuple[bool, str]:
    """模擬點設施：非 TRANSPORT 應開 FacilityPanel，路徑必須全通。"""
    scene = ROOT / "UI/facility_panel.tscn"
    script = ROOT / "scripts/controllers/FacilityPanel.gd"
    errors = check_gd_paths(scene, script)
    if errors:
        return False, "; ".join(errors)
    if facility_id == "fac_agency":
        return True, "agency panel paths ok"
    return True, f"{facility_id} panel paths ok"


def simulate_map_hub_navigation() -> tuple[bool, str]:
    scene = ROOT / "UI/MapHub.tscn"
    script = ROOT / "scripts/controllers/MapHubController.gd"
    errors = check_gd_paths(scene, script)
    if errors:
        return False, "; ".join(errors)
    required = [
        "Background",
        "UI_Layer/TopPanel/TopBox/TitleLabel",
        "UI_Layer/FacilityPanel/FacilityBox/FacilityScroll/FacilityContainer",
        "UI_Layer/FooterBar/BtnExitMap",
        "WorldMapLayer/WorldPanel/WorldVBox/HeaderBox/BtnClose",
    ]
    nodes = parse_tscn_nodes(scene)
    for rel in required:
        if not path_exists(nodes, rel):
            return False, f"缺少必要節點 {rel}"
    return True, "map hub navigation paths ok"


def simulate_dialogue_panel() -> tuple[bool, str]:
    scene = ROOT / "UI/dialogue_panel.tscn"
    script = ROOT / "scripts/controllers/dialogue_panel.gd"
    errors = check_gd_paths(scene, script) + check_tscn_nodepaths(scene)
    if errors:
        return False, "; ".join(errors)
    return True, "dialogue panel paths ok"


def simulate_transport_facility() -> tuple[bool, str]:
    """TRANSPORT 設施應走世界地圖層，不 instantiate FacilityPanel。"""
    scene = ROOT / "UI/MapHub.tscn"
    nodes = parse_tscn_nodes(scene)
    for rel in [
        "WorldMapLayer",
        "WorldMapLayer/WorldPanel/WorldVBox/CityContainer/ParisButton",
    ]:
        if not path_exists(nodes, rel):
            return False, f"TRANSPORT 路徑缺失 {rel}"
    return True, "transport/world map paths ok"


def _read_tres_field(path: Path, field: str) -> str:
    text = path.read_text(encoding="utf-8")
    m = re.search(rf"^{field} = (.+)$", text, re.MULTILINE)
    if not m:
        return ""
    return _parse_tres_value(m.group(1))


def _tres_has_texture_ref(path: Path, png_rel: str) -> bool:
    return png_rel in path.read_text(encoding="utf-8")


def simulate_heroine_names_and_portraits() -> tuple[bool, str]:
    expected = {
        "artist_001": ("一号", "artist_001_avatar.png", "artist_001_portrait.png"),
        "artist_002": ("二号", "artist_002_avatar.png", "artist_002_portrait.png"),
        "artist_003": ("米语", "artist_003_avatar.png", "artist_003_portrait.png"),
    }
    for artist_id, (name, avatar_name, portrait_name) in expected.items():
        tres = ROOT / f"data/artists/{artist_id}/{artist_id}.tres"
        if not tres.exists():
            return False, f"缺少 {artist_id}.tres"
        if _read_tres_field(tres, "artist_name") != name:
            return False, f"{artist_id} 名稱應為 {name}"
        avatar_dir = ROOT / f"assets/characters/artists/{artist_id}/avatar"
        portrait_dir = ROOT / f"assets/characters/artists/{artist_id}/portrait"
        if not avatar_dir.is_dir() or not portrait_dir.is_dir():
            return False, f"{artist_id} 缺少 avatar/portrait 資料夾"
        paths = (ROOT / "scripts/resources/CharacterVisualPaths.gd").read_text(encoding="utf-8")
        if "_avatar.png" not in paths or "_portrait.png" not in paths:
            return False, "CharacterVisualPaths 未約定標準檔名"
    return True, "女主角命名與視覺路徑約定已對齊"


def simulate_shopkeeper_portrait() -> tuple[bool, str]:
    tres = ROOT / "data/npcs/npc_shopkeeper_01/npc_shopkeeper_01.tres"
    npc_id = "npc_shopkeeper_01"
    avatar_dir = ROOT / f"assets/characters/npcs/{npc_id}/avatar"
    if not avatar_dir.is_dir():
        return False, f"缺少 {avatar_dir}"
    if 'npc_id = "npc_shopkeeper_01"' not in tres.read_text(encoding="utf-8"):
        return False, "npc_shopkeeper_01.tres id 不正確"
    return True, "shopkeeper visual folders ok"


def simulate_artist_resource_has_portrait_fields() -> tuple[bool, str]:
    script = (ROOT / "scripts/resources/Artist_Resource.gd").read_text(encoding="utf-8")
    for field in ("avatar: Texture2D", "portrait: Texture2D"):
        if field not in script:
            return False, f"ArtistResource 缺少 {field}"
    manager = (ROOT / "scripts/autoload/ArtistManager.gd").read_text(encoding="utf-8")
    if "get_artist_portrait" not in manager:
        return False, "ArtistManager 缺少 get_artist_portrait"
    return True, "artist portrait API ok"


def no_bare_mainpanel_in_facility_script() -> tuple[bool, str]:
    text = (ROOT / "scripts/controllers/FacilityPanel.gd").read_text(encoding="utf-8")
    if re.search(r'\$MainPanel/', text):
        return False, "FacilityPanel.gd 仍含錯誤的 $MainPanel/ 前綴（應為 $DimBackground/MainPanel/）"
    return True, "no bare MainPanel references"


def _parse_tres_value(raw: str) -> str:
    value = raw.strip()
    if value.startswith('"') and value.endswith('"'):
        return value[1:-1]
    return value


def parse_facility_tres(path: Path) -> dict[str, str]:
    text = path.read_text(encoding="utf-8")
    data: dict[str, str] = {}
    for key in ("facility_id", "facility_name", "type"):
        m = re.search(rf"^{key} = (.+)$", text, re.MULTILINE)
        if m:
            data[key] = _parse_tres_value(m.group(1))
    npc_paths = re.findall(r'path="(res://data/npcs/[^"]+)"', text)
    data["npc_paths"] = npc_paths
    return data


def load_location_facilities(location_path: Path) -> list[str]:
    text = location_path.read_text(encoding="utf-8")
    return re.findall(r'path="(res://data/facilities/[^"]+\.tres)"', text)


def simulate_location_facility_data() -> tuple[bool, str]:
    locations = sorted((ROOT / "data/locations").glob("screen_*.tres"))
    if len(locations) != 5:
        return False, f"預期 5 個地點，實際 {len(locations)}"
    seen_ids: set[str] = set()
    for loc in locations:
        fac_paths = load_location_facilities(loc)
        if not fac_paths:
            return False, f"{loc.name} 未綁定設施"
        for fac_rel in fac_paths:
            fac_path = ROOT / fac_rel.replace("res://", "")
            if not fac_path.exists():
                return False, f"設施資源不存在 {fac_rel}"
            fac = parse_facility_tres(fac_path)
            fid = fac.get("facility_id", "")
            fname = fac.get("facility_name", "")
            if not fid or not fname:
                return False, f"{fac_path.name} 缺少 facility_id 或 facility_name"
            if fid in seen_ids:
                return False, f"重複 facility_id: {fid}"
            seen_ids.add(fid)
    return True, f"{len(locations)} 個地點、{len(seen_ids)} 個設施資料完整"


def simulate_agency_empty_npcs() -> tuple[bool, str]:
    fac_path = ROOT / "data/facilities/screen1_aero_metropolis/fac_agency.tres"
    fac = parse_facility_tres(fac_path)
    if fac.get("facility_id") != "fac_agency":
        return False, "fac_agency id 不符"
    if fac.get("npc_paths"):
        return False, "經紀公司不應有 NPC（應顯示空狀態提示）"
    return True, "agency empty npc list ok"


def simulate_shop_npc_dialogue() -> tuple[bool, str]:
    fac_path = ROOT / "data/facilities/screen1_aero_metropolis/fac_shop.tres"
    fac = parse_facility_tres(fac_path)
    npc_paths = fac.get("npc_paths", [])
    if len(npc_paths) != 1:
        return False, "便利商店應有 1 名 NPC"
    npc_path = ROOT / npc_paths[0].replace("res://", "")
    text = npc_path.read_text(encoding="utf-8")
    if "default_dialogue" not in text:
        return False, "商店老闆缺少 default_dialogue"
    if "seq_shopkeeper_intro.tres" not in text:
        return False, "商店老闆對話序列路徑錯誤"
    return True, "shop npc dialogue ok"


def simulate_airport_transport() -> tuple[bool, str]:
    fac_path = ROOT / "data/facilities/screen1_aero_metropolis/fac_airport.tres"
    fac = parse_facility_tres(fac_path)
    if fac.get("type") != "6":
        return False, f"機場 type 應為 6(TRANSPORT)，實際 {fac.get('type')}"
    return True, "airport TRANSPORT ok"


def simulate_opening_profile_fields() -> tuple[bool, str]:
    player = (ROOT / "scripts/autoload/PlayerManager.gd").read_text(encoding="utf-8")
    protagonist = (ROOT / "scripts/autoload/ProtagonistManager.gd").read_text(encoding="utf-8")
    resolver = (ROOT / "scripts/autoload/DialogueVariableResolver.gd").read_text(encoding="utf-8")
    if "company_name_locked" not in player or "finalize_company_name" not in player:
        return False, "PlayerManager 缺少公司鎖定邏輯"
    if "profile_locked" not in protagonist or "lock_profile" not in protagonist:
        return False, "ProtagonistManager 缺少姓名鎖定邏輯"
    if "player_company" not in resolver or "agency_name" not in resolver:
        return False, "DialogueVariableResolver 缺少公司變數"
    dialogue = (ROOT / "scripts/controllers/dialogue_panel.gd").read_text(encoding="utf-8")
    if "next_button" in dialogue or "_advance_dialogue" not in dialogue:
        return False, "DialoguePanel 應改為點擊推進"
    if (ROOT / "UI/dialogue_panel.tscn").read_text(encoding="utf-8").find("NextButton") >= 0:
        return False, "dialogue_panel.tscn 仍含 NextButton"
    if not (ROOT / "scripts/ui/OpeningProfileDialog.gd").exists():
        return False, "缺少 OpeningProfileDialog"
    return True, "opening profile + click dialogue ok"


def simulate_opening_artist_pick() -> tuple[bool, str]:
    pick_dialog = ROOT / "scripts/ui/OpeningArtistPickDialog.gd"
    artist_mgr = (ROOT / "scripts/autoload/ArtistManager.gd").read_text(encoding="utf-8")
    flow = (ROOT / "scripts/autoload/GameFlowManager.gd").read_text(encoding="utf-8")
    root_ctrl = (ROOT / "scripts/controllers/GameRootController.gd").read_text(encoding="utf-8")
    if not pick_dialog.exists():
        return False, "缺少 OpeningArtistPickDialog"
    if "sign_initial_artist" not in artist_mgr or "opening_pick" not in artist_mgr:
        return False, "ArtistManager 缺少開局簽約 API（opening_pick）"
    if "initial_sign_completed" not in flow or "needs_initial_sign" not in flow:
        return False, "GameFlowManager 缺少 initial_sign 狀態"
    if "OpeningArtistPickDialog" not in root_ctrl or "_try_open_initial_artist_pick" not in root_ctrl:
        return False, "GameRootController 未接入開局 3 選 1"
    pick_text = pick_dialog.read_text(encoding="utf-8")
    if "OPENING_ACTIONS" not in pick_text:
        return False, "OpeningArtistPickDialog 未改為行動三選一"
    if "get_initial_signable_artist_resources()" in root_ctrl:
        return False, "通告中心仍列出開局候選簽約"
    return True, "opening 3-pick-1 dialog + flow ok"


def simulate_day_work_report_panel_refs() -> tuple[bool, str]:
    panel = (ROOT / "scripts/ui/DayWorkReportPanel.gd").read_text(encoding="utf-8")
    if "$Root/MainBox/DateLabel" in panel or "$Root/MainBox/MoneyLabel" in panel:
        return False, "DateLabel/MoneyLabel 路徑錯誤（應在 Header 下或使用成員引用）"
    if "_date_label" not in panel or "_money_label" not in panel:
        return False, "DayWorkReportPanel 缺少標籤成員引用"
    if "_click_layer" not in panel or "ClickLayer" not in panel:
        return False, "DayWorkReportPanel 缺少全屏點擊層"
    if "MOUSE_FILTER_IGNORE" not in panel:
        return False, "內容層應 IGNORE 滑鼠以讓 ClickLayer 接收點擊"
    return True, "day work report label refs ok"


def simulate_facility_exit_triggers_exploration_finish() -> tuple[bool, str]:
    facility = (ROOT / "scripts/controllers/FacilityPanel.gd").read_text(encoding="utf-8")
    maphub = (ROOT / "scripts/controllers/MapHubController.gd").read_text(encoding="utf-8")
    root_ctrl = (ROOT / "scripts/controllers/GameRootController.gd").read_text(encoding="utf-8")
    if "signal closed" not in facility:
        return False, "FacilityPanel 缺少 closed 信號"
    if "exploration_finished" not in maphub or "_on_facility_panel_closed" not in maphub:
        return False, "MapHub 未在離開設施時 emit exploration_finished"
    if "_on_map_exploration_finished" not in root_ctrl or "_finish_map_exploration" not in root_ctrl:
        return False, "GameRootController 未接入 exploration_finished"
    return True, "facility exit -> exploration_finished ok"


ROUNDS: list[tuple[str, callable]] = [
    ("MapHub 節點路徑", simulate_map_hub_navigation),
    ("FacilityPanel 節點路徑", lambda: simulate_facility_click("fac_agency")),
    ("DialoguePanel 節點路徑", simulate_dialogue_panel),
    ("經紀公司點擊（fac_agency）", lambda: simulate_facility_click("fac_agency")),
    ("交通設施世界地圖", simulate_transport_facility),
    ("FacilityPanel 路徑前綴檢查", no_bare_mainpanel_in_facility_script),
    ("五屏地點設施資料", simulate_location_facility_data),
    ("經紀公司空 NPC 狀態", simulate_agency_empty_npcs),
    ("便利商店 NPC 對話", simulate_shop_npc_dialogue),
    ("機場 TRANSPORT 類型", simulate_airport_transport),
    ("女主角命名與頭像", simulate_heroine_names_and_portraits),
    ("商店老闆頭像", simulate_shopkeeper_portrait),
    ("ArtistResource 頭像欄位", simulate_artist_resource_has_portrait_fields),
    ("開局設定鎖定欄位", simulate_opening_profile_fields),
    ("開局 3 選 1 簽約", simulate_opening_artist_pick),
    ("通告進行中面板節點", simulate_day_work_report_panel_refs),
    ("離開設施結束探索", simulate_facility_exit_triggers_exploration_finish),
]


def main() -> None:
    failed: list[str] = []
    print("=== MapHub UI 沙盘（17 輪）===\n")
    for i, (label, fn) in enumerate(ROUNDS, 1):
        ok, detail = fn()
        status = "PASS" if ok else "FAIL"
        print(f"第 {i} 輪 [{status}] {label}: {detail}")
        if not ok:
            failed.append(label)
    print()
    if failed:
        print(f"失敗：{', '.join(failed)}")
        sys.exit(1)
    print("全部 17 輪通過。")


if __name__ == "__main__":
    main()
