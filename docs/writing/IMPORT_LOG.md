# 匯入紀錄：MyIdolGameScript-main

來源：`/Users/luke/MyIdolGameScript-main`  
**本次同步**：2026-06-20（對齊 2026-06-19 vault 定案）  
上一輪：2026-06-18（部分主線 + 人設）

---

## 同步範圍

| 區塊 | 動作 |
|------|------|
| `00_Project_Spec/` | **新增** 5 份 spec（含 `项目梳理_明星志愿3精神续作.md`、`obi更新版本.md`） |
| `01_Characters/` | **覆寫** artist_001～003；**新增** npc_shopkeeper_01、Yuko/Valeria/Puzzle_Sets、大地图随机对话 |
| `02_Story_Events/` | **整包替換** 為 Artists/Npcs 6.19 結構（81 篇 md） |
| `plots/start_flow.md` | **覆寫**（vault 簡版；詳細開局見 `00_Project_Spec/开局流程_取名与三选一签约.md`） |
| `04_Characters_image/` | **新增** 3 張參考圖 |
| `secretary.md` | **保留**（專案獨有，未在 vault） |
| `CHARACTER_REGISTRY.md` 等 | **保留**並手動更新 event 登記 |

---

## 角色 id 對照（不變）

| id | 顯示名 | 舊代號 |
|----|--------|--------|
| `artist_001` | Yuka | yuka |
| `artist_002` | Valeria | valeria |
| `artist_003` | 米语 | Puzzle |
| `secretary` | 小唯 | S_Yui / 金妮 |
| `npc_shopkeeper_01` | 商店老板 | — |

---

## 主線劇本（新結構 · 已廢棄舊檔名）

| 艺人 | sign md | meeting md | event_id |
|------|---------|------------|----------|
| 001 | `Artists/artist_001/00_street_sign_01.md` | `01_first_meeting_01.md` | `story_sign_artist_001_street_01` / `story_meeting_artist_001_first_session_01` |
| 002 | `00_theater_sign_01.md` | `01_first_meeting_01.md` | `story_sign_artist_002_theater_01` / `story_meeting_artist_002_first_session_01` |
| 003 | `00_office_sign_01.md` | `01_first_meeting_01.md` | `story_sign_artist_003_day1_office_01` / `story_meeting_artist_003_first_session_01` |

**已刪除（舊路徑）**：`1_Main_Story/artist_*/00_first_meeting_sign.md`、`01_day1_office_01.md`、`02_first_sunday_welcome_01.md`

---

## 日常循環（新增 · 專案原先無）

- `Meeting_Weekly/`：001/002/003 各 3 篇 Basic 周會聊天
- `Schedule_Result/`：三人 × fail/success/perfect 各 3 篇（27 篇）
- `Map_Encounters/`：三人各 5 篇 Permanent + 占位
- `Npcs/npc_shopkeeper_01/`：enter×3、purchase_leave×3、leave_empty×3
- 台詞庫台帳 ×3

---

## 尚未執行（Godot 側 · 2026-06-20 更新後）

1. ~~`data/story_events/` 目錄改為 `main/artists/`~~ ✅ 已完成（6 則主線）
2. ~~新 `event_id` 生成 `.tres`~~ ✅ `tools/sync_main_story_tres.py`
3. ~~開局 UI 行動三選一~~ ✅ `OpeningArtistPickDialog.gd`
4. `daily/artists/`、`daily/npcs/` 日常池 `.tres`（Meeting_Weekly / Schedule_Result 等 ~75 篇 md 待匯入）
5. `npc_shopkeeper_01` 首次進店 intro `.tres`
6. 003 電視前置若需獨立 event（目前用 `StoryBeatTransition` 旁白 bridge）
7. `git commit`（需勇者大人指示）
