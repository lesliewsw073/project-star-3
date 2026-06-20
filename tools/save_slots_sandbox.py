#!/usr/bin/env python3
"""多槽存檔 UI 與自動存檔輪替接線檢查。"""

from __future__ import annotations

import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
SAVE_MGR = ROOT / "scripts/managers/SaveManager.gd"
DIALOG = ROOT / "scripts/ui/SaveSlotPickerDialog.gd"
GAME_ROOT = ROOT / "scripts/controllers/GameRootController.gd"


def _read(path: Path) -> str:
    return path.read_text(encoding="utf-8")


def check_save_manager_api() -> None:
    text = _read(SAVE_MGR)
    for token in (
        "MANUAL_SLOT_COUNT: int = 5",
        "AUTO_SLOT_COUNT: int = 2",
        "ROSTER_PREVIEW_SLOTS: int = 4",
        "enum SlotKind",
        "peek_slot_summary",
        "get_all_slot_summaries",
        "save_slot",
        "load_slot",
        "try_weekly_auto_save",
        "can_player_save_to_slot",
        "自動存檔槽僅由系統",
        "auto_rotate.json",
        "signed_artist_ids",
        "company_name",
    ):
        if token not in text:
            raise AssertionError(f"SaveManager 缺少 {token}")


def check_dialog_ui() -> None:
    text = _read(DIALOG)
    for token in (
        "class_name SaveSlotPickerDialog",
        "存檔時間",
        "遊戲日期",
        "公司名稱",
        "ConfirmationDialog",
        "僅系統週末自動寫入",
        "can_player_save_to_slot",
        "覆蓋存檔",
        "ROSTER_PREVIEW_SLOTS",
        "自動存檔",
        "手動存檔",
    ):
        if token not in text:
            raise AssertionError(f"SaveSlotPickerDialog 缺少 {token}")
    if "var is_auto: bool" not in text:
        raise AssertionError("SaveSlotPickerDialog 未區分手動／自動槽 UI")


def check_game_root_wiring() -> None:
    text = _read(GAME_ROOT)
    for token in (
        "SaveSlotPickerDialogScript",
        "_setup_save_slot_picker_dialog",
        "_on_open_save_slots_pressed",
        "存檔／讀檔",
        "try_weekly_auto_save",
        "_apply_post_load_refresh",
    ):
        if token not in text:
            raise AssertionError(f"GameRootController 缺少 {token}")
    if "_save_slot1_button" in text:
        raise AssertionError("GameRootController 仍保留舊單槽按鈕")
    if "_on_save_slot1_pressed" in text:
        raise AssertionError("GameRootController 仍保留舊單槽處理")


def check_auto_rotate_independent() -> None:
    text = _read(SAVE_MGR)
    if "auto_rotate.json" not in text:
        raise AssertionError("自動存檔輪替未持久化")
    if "_last_auto_save_week_token" not in text:
        raise AssertionError("缺少每週自動存檔去重")


def main() -> None:
    check_save_manager_api()
    check_dialog_ui()
    check_game_root_wiring()
    check_auto_rotate_independent()
    print("save_slots_sandbox: 全部檢查通過。")


if __name__ == "__main__":
    try:
        main()
    except AssertionError as exc:
        print(f"save_slots_sandbox: 失敗 — {exc}", file=sys.stderr)
        sys.exit(1)
