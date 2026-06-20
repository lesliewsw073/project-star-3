#!/usr/bin/env python3
"""道具／貨幣／物品欄 Phase 0 沙盒（靜態檢查 + 邏輯模擬）。"""

from __future__ import annotations

import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
ITEM_RES = ROOT / "scripts/resources/ItemResource.gd"
ITEM_DB = ROOT / "scripts/autoload/ItemDatabase.gd"
INV = ROOT / "scripts/managers/InventoryManager.gd"
COMPANY = ROOT / "scripts/managers/CompanyItemManager.gd"
HOME = ROOT / "scripts/managers/PlayerHomeManager.gd"
ITEM_MGR = ROOT / "scripts/managers/ItemManager.gd"
MEETING_GIFT_UI = ROOT / "scripts/ui/MeetingGiftPickerDialog.gd"
GAME_ROOT = ROOT / "scripts/controllers/GameRootController.gd"
PLAYER = ROOT / "scripts/autoload/PlayerManager.gd"
SAVE = ROOT / "scripts/managers/SaveManager.gd"
PROJECT = ROOT / "project.godot"
ITEMS_DIR = ROOT / "data/items"
README = ROOT / "docs/writing/README_ITEMS.md"

REQUIRED_ITEMS = (
    "comp_item_meeting_plant_01",
    "comp_item_meeting_sofa_02",
    "attr_item_energy_drink_01",
    "attr_item_perfume_01",
    "story_item_old_letter_01",
    "gift_artist_001_handmade_01",
)

ITEM_ID_PATTERN = re.compile(
    r"^(comp_item|attr_item|story_item|gift)_[a-z0-9_]+$"
)


def _read(path: Path) -> str:
    return path.read_text(encoding="utf-8")


def check_files_exist() -> None:
    for path in (ITEM_RES, ITEM_DB, INV, COMPANY, HOME, ITEM_MGR, README):
        if not path.is_file():
            raise AssertionError(f"缺少 {path.relative_to(ROOT)}")


def check_autoloads() -> None:
    text = _read(PROJECT)
    for name in ("ItemDatabase", "CompanyItemManager", "PlayerHomeManager", "ItemManager"):
        if f'{name}="*' not in text:
            raise AssertionError(f"project.godot 未註冊 {name}")


def check_player_public_opinion() -> None:
    text = _read(PLAYER)
    for token in ("company_public_opinion", "add_public_opinion", "reduce_public_opinion"):
        if token not in text:
            raise AssertionError(f"PlayerManager 缺少 {token}")


def check_save_hooks() -> None:
    text = _read(SAVE)
    for token in ("company_items", "player_home", "company_public_opinion"):
        if token not in text:
            raise AssertionError(f"SaveManager 缺少 {token}")


def parse_item_tres(path: Path) -> dict:
    text = _read(path)
    out = {"path": path}
    for field in ("item_id", "item_name", "meeting_display_key"):
        m = re.search(rf'^{field}\s*=\s*"(.*)"', text, re.M)
        out[field] = m.group(1) if m else ""
    m_cat = re.search(r"^item_category\s*=\s*(\d+)", text, re.M)
    out["item_category"] = int(m_cat.group(1)) if m_cat else None
    m_rep = re.search(r"^reputation_bonus\s*=\s*(\d+)", text, re.M)
    out["reputation_bonus"] = int(m_rep.group(1)) if m_rep else 0
    m_op = re.search(r"^public_opinion_bonus\s*=\s*(\d+)", text, re.M)
    out["public_opinion_bonus"] = int(m_op.group(1)) if m_op else 0
    return out


def load_items() -> list[dict]:
    return [parse_item_tres(p) for p in sorted(ITEMS_DIR.rglob("*.tres"))]


def check_item_ids(items: list[dict]) -> None:
    if len(items) < 6:
        raise AssertionError(f"至少 6 则占位道具，实际 {len(items)}")
    ids = [i["item_id"] for i in items if i["item_id"]]
    if len(ids) != len(set(ids)):
        raise AssertionError("item_id 重复")
    for iid in ids:
        if not ITEM_ID_PATTERN.match(iid):
            raise AssertionError(f"item_id 命名不规范：{iid}")
    for required in REQUIRED_ITEMS:
        if required not in ids:
            raise AssertionError(f"缺少占位道具 {required}")


def simulate_company_marginal_bonus() -> None:
    """模拟 CompanyItemManager 边际声望逻辑。"""
    owned = []
    applied_rep = 0
    applied_op = 0
    catalog = {
        "comp_item_meeting_plant_01": {"reputation_bonus": 50, "public_opinion_bonus": 0},
        "comp_item_meeting_sofa_02": {"reputation_bonus": 100, "public_opinion_bonus": 20},
    }

    def max_bonus(kind: str) -> int:
        best = 0
        for oid in owned:
            best = max(best, catalog[oid][kind])
        return best

    def purchase(oid: str) -> tuple[int, int]:
        nonlocal applied_rep, applied_op
        owned.append(oid)
        new_rep = max_bonus("reputation_bonus")
        new_op = max_bonus("public_opinion_bonus")
        d_rep = new_rep - applied_rep
        d_op = new_op - applied_op
        applied_rep, applied_op = new_rep, new_op
        return d_rep, d_op

    d1 = purchase("comp_item_meeting_plant_01")
    if d1 != (50, 0):
        raise AssertionError(f"首购 plant 边际应为 (50,0)，得 {d1}")
    d2 = purchase("comp_item_meeting_sofa_02")
    if d2 != (50, 20):
        raise AssertionError(f"二购 sofa 边际应为 (50,20)，得 {d2}")


def simulate_bag_categories(items: list[dict]) -> None:
    bag_cats = {1, 2}  # ATTRIBUTE, STORY
    for item in items:
        cat = item.get("item_category")
        iid = item["item_id"]
        if cat in bag_cats:
            continue
        if cat in (0, 3):  # COMPANY, ARTIST_GIFT
            continue
        raise AssertionError(f"未知 category {cat} @ {iid}")


def simulate_stat_cap() -> None:
    """属性满则正向不加（与 ArtistInstance._clamped_positive_delta 一致）。"""

    def clamped(current: int, delta: int, max_value: int) -> int:
        if delta == 0:
            return 0
        if delta < 0:
            return max(delta, -current)
        if current >= max_value:
            return 0
        return min(delta, max_value - current)

    if clamped(999, 5, 999) != 0:
        raise AssertionError("满值不应再增加")
    if clamped(990, 5, 999) != 5:
        raise AssertionError("未满应全加")
    if clamped(10, -20, 999) != -10:
        raise AssertionError("负向不应低于 0")


def check_shop_wiring() -> None:
    item_text = _read(ITEM_MGR)
    for token in ("get_shop_catalog", "can_purchase_from_shop", "SECRETARY_ID"):
        if token not in item_text:
            raise AssertionError(f"ItemManager 缺少 {token}")
    shop_ui = ROOT / "scripts/ui/ShopPurchaseDialog.gd"
    facility = ROOT / "scripts/controllers/FacilityPanel.gd"
    if not shop_ui.is_file():
        raise AssertionError("缺少 ShopPurchaseDialog.gd")
    fac_text = _read(facility)
    for token in ("ShopPurchaseDialogScript", "_on_shop_pressed", "購買道具"):
        if token not in fac_text:
            raise AssertionError(f"FacilityPanel 缺少 {token}")


def simulate_shop_catalog() -> None:
    shop_count = 0
    for path in sorted(ITEMS_DIR.rglob("*.tres")):
        text = _read(path)
        if "gift_" in path.name:
            continue
        m = re.search(r"^shop_price\s*=\s*(\d+)", text, re.M)
        if m and int(m.group(1)) > 0:
            shop_count += 1
    if shop_count < 4:
        raise AssertionError(f"至少 4 则可商店购买道具，实际 {shop_count}")


def check_meeting_gift_wiring() -> None:
    inv_text = _read(INV)
    if "get_giftable_entries" not in inv_text:
        raise AssertionError("InventoryManager 缺少 get_giftable_entries")
    item_text = _read(ITEM_MGR)
    if "build_gift_effect_summary" not in item_text:
        raise AssertionError("ItemManager 缺少 build_gift_effect_summary")
    if not MEETING_GIFT_UI.is_file():
        raise AssertionError("缺少 MeetingGiftPickerDialog.gd")
    root_text = _read(GAME_ROOT)
    for token in (
        "MeetingGiftPickerDialogScript",
        "_execute_meeting_inventory_gift",
        "try_gift_to_artist",
        "_on_test_seed_inventory_items",
    ):
        if token not in root_text:
            raise AssertionError(f"GameRootController 缺少 {token}")


def main() -> None:
    print("=== item_system_sandbox ===")
    check_files_exist()
    print("  [PASS] 核心文件")
    check_autoloads()
    print("  [PASS] Autoload")
    check_player_public_opinion()
    print("  [PASS] PlayerManager 口碑")
    check_save_hooks()
    print("  [PASS] SaveManager")
    items = load_items()
    check_item_ids(items)
    print(f"  [PASS] {len(items)} 则 item_id")
    simulate_company_marginal_bonus()
    print("  [PASS] 公司物品边际声望")
    simulate_bag_categories(items)
    print("  [PASS] 物品栏类别")
    simulate_stat_cap()
    print("  [PASS] 属性满值截断")
    check_meeting_gift_wiring()
    print("  [PASS] 週會送禮接物品欄")
    check_shop_wiring()
    print("  [PASS] 商店購買接線")
    simulate_shop_catalog()
    print("  [PASS] 商店目錄道具")
    print("item_system_sandbox 通過。")


if __name__ == "__main__":
    try:
        main()
    except AssertionError as exc:
        print(f"  [FAIL] {exc}")
        sys.exit(1)
