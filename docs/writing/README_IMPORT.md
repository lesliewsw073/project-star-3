# MyIdolGameScript → project-star-3 匯入指南

> 對齊：`00_Project_Spec/项目梳理_明星志愿3精神续作.md` §0.5 I／J  
> 2026-06-19 格式標準：[`00_Project_Spec/剧本event正文格式标准.md`](00_Project_Spec/剧本event正文格式标准.md)  
> 角色 id：[`CHARACTER_REGISTRY.md`](CHARACTER_REGISTRY.md)  
> 劇本 frontmatter：[`README_STORY.md`](README_STORY.md)  
> 最近同步：[`IMPORT_LOG.md`](IMPORT_LOG.md)

---

## 結論（先講）

**可以帶過來，而且你的 GitHub 資料夾命名已經和定案一致。**

| MyIdolGameScript（你現有） | project-star-3 落點 | 用途 |
|---------------------------|---------------------|------|
| `00_Project_Spec/` | `docs/writing/00_Project_Spec/` | 專案 spec、開局、event 格式 |
| `01_Characters/` | `docs/writing/01_Characters/` | 人設長文 |
| `02_Story_Events/` | `docs/writing/02_Story_Events/` | 劇本（Obsidian vault 核心） |
| `plots/` | `docs/writing/plots/` | 流程大綱（如 `start_flow.md`） |
| `04_Characters_Image/` | `assets/characters/` | **僅圖片**進 Godot 資源樹 |
| `README.md` | `MyIdolGameScript_README.md` 或合併 | 說明 |

**不需要重寫劇情**；匯入時主要是：**補 frontmatter、對齊 id、改變數占位、搬圖片路徑**。

---

## 推薦同步方式（三選一）

### 方案 A：整包併入本 repo（最簡單，推薦）

1. Windows 上把 `MyIdolGameScript` 的內容 **複製進** `project-star-3/docs/writing/`（保留 `01_`、`02_` 前綴）。
2. 圖片從 `04_Characters_Image/` 複製到 `assets/characters/artists/`、`npcs/` 等對應子目錄。
3. Git push；macOS 上 pull 即可編輯 + 請 AI 批量對齊。
4. Obsidian vault 根目錄改指向 **`project-star-3/docs/writing/`**（一個 vault 管全部筆記）。

### 方案 B：維持獨立 repo + Git submodule

```bash
# 在 project-star-3 根目錄
git submodule add git@github.com:leslieosw073/MyIdolGameScript.git docs/writing/vault
```

- 優點：劇本 repo 獨立、權限可分。
- 缺點：圖片仍要手動同步到 `assets/`；AI 讀檔路徑多一層。

### 方案 C：維持兩 repo，僅用 GitHub 當中轉

- Windows 寫在 `MyIdolGameScript` → push。
- macOS 定期 `git clone` / pull 到本機，再 **rsync 或手動複製** 到 `docs/writing/`。
- 適合過渡期；長期仍建議方案 A。

---

## 資料夾對照（Obsidian ↔ Godot）

### `01_Characters/` → 人設

| 寫作檔建議路徑 | 程式資源 |
|----------------|----------|
| `01_Characters/artist_001.md` | `data/artists/artist_001/artist_001.tres` |
| `01_Characters/secretary.md` | `data/npcs/secretary/npc_secretary.tres` |
| `01_Characters/npc_shopkeeper_01.md` | `data/npcs/npc_shopkeeper_01/npc_shopkeeper_01.tres` |
| `01_Characters/rival_001.md` | `data/rivals/rival_001/rival_001.tres` |

人設 frontmatter 最少欄位：

```yaml
---
id: artist_001
type: artist          # protagonist | secretary | artist | rival | npc
display_name: （創作用真名）
gender: female
home_agency_id:       # 我方 16 人見 CHARACTER_REGISTRY
status: draft
godot_resource: res://data/artists/artist_001/artist_001.tres
---
```

> **養成修正 8 欄**（`contract_diff_mod` 等 + `stress_gain_mod` / `fatigue_gain_mod` / `satisfaction_gain_mod`）只在 Godot `.tres` 填；人設 md 可寫折疊 callout，不要寫進 frontmatter YAML。

### `02_Story_Events/` → 劇本

與定案目錄一致（見 `00_Project_Spec/剧本event正文格式标准.md`）：

```
02_Story_Events/
├── 1_Main_Story/
│   ├── Artists/artist_NNN/
│   └── Npcs/npc_shopkeeper_01/
├── 2_Daily_Loops/
│   ├── Artists/
│   │   ├── Meeting_Weekly/artist_NNN/
│   │   ├── Schedule_Result/artist_NNN/{fail|success|perfect}/
│   │   ├── Visit_Flavor/artist_NNN/
│   │   ├── Map_Encounters/artist_NNN/
│   │   ├── Hospital/ · Award_Speech/
│   │   # 無 Follow_Flavor
│   └── Npcs/npc_shopkeeper_01/{enter|purchase_leave|leave_empty}/
├── 3_Cross_Interactions/Duo/
├── 4_Protagonist/
└── 5_Secretary/
```

每張劇本卡 **必須有 frontmatter**（舊稿沒有也可後補）：

```yaml
---
event_id: story_follow_gig_bar_01    # 全局唯一，见 README_STORY 命名表
event_title: 酒吧駐唱後台
arc_type: flavor_repeat
owner: artist_001
story_channel: follow              # follow | visit | meeting | sign | ...
participants: [artist_001]
character_id: artist_001
execute_once: false
affection_settlement: once
affection_delta: 3
task_signature: gig:gig_bar_singer_01   # follow/visit 触发用
priority: 10
required_flags: {}
sets_flags: {}
---
```

### `plots/start_flow.md` → 開局流程

- 企劃用，不直接進 Godot。
- 詳細定案：`00_Project_Spec/开局流程_取名与三选一签约.md`
- 對齊程式：`OpeningProfileDialog` → **行動三選一** → 各線 sign → 各線 first_session meeting
- id 引用：`artist_001`～`003`、`secretary`、`protagonist`

### `04_Characters_Image/` → 僅資產

| 圖片用途 | 建議 Godot 路徑 |
|----------|-----------------|
| 藝人視覺 | `assets/characters/artists/artist_NNN/{avatar,portrait,cg}/` |
| NPC | `assets/characters/npcs/{npc_id}/{avatar,portrait,cg}/` |
| NPC 資料 | `data/npcs/{npc_id}/npc_{...}.tres`（劇情 NPC 資料夾名 = 邏輯 id；秘書例外為 `secretary/`） |
| rival | `assets/characters/rivals/rival_NNN/{avatar,portrait,cg}/` |

規格見 [`README_CHARACTER_ASSETS.md`](README_CHARACTER_ASSETS.md)。檔名：`{id}_avatar.png`、`{id}_portrait.png`、`{id}_cg_{場景}.png`。

---

## 匯入時必須對齊的欄位

### 角色 id（硬對齊）

| 類型 | 格式 | 範例 |
|------|------|------|
| 主角 | 固定 | `protagonist` |
| 秘書 | 固定 | `secretary`（不是 `npc_secretary_01`） |
| 我方藝人 | `artist_NNN` | `artist_001`～`016` |
| 競爭對手 | `rival_NNN` | `rival_001`～`010` |
| 劇情 NPC | `npc_{描述}_{NN}` | `npc_shopkeeper_01` |

### 常見舊稿問題 → 修正方式

| 舊寫法 | 應改為 |
|--------|--------|
| 一号、小雪、女主A | `speaker_id: artist_001` + display_name 欄 |
| 陸星河、制作人 | `{player_full_name}` / `{player_address}` |
| 性格：细腻 | 刪除或改為企劃備註；程式已無 personality_tags |
| 同一劇本 follow+visit 共用 | 拆成 `story_follow_*` 與 `story_visit_*` 兩張卡 |
| 004/005 雙人線各存一份 | 只存 `3_Cross_Interactions/Duo/`，個人夾 wikilink |
| `001` 省略前綴 | 一律 `artist_001` |

### 對話正文格式

```markdown
| speaker_id | speaker_name | text |
|------------|--------------|------|
| artist_001 | | {player_address}，今天還好嗎？ |
| protagonist | | 還行。 |
```

`speaker_name` 可留空，運行時由 `CharacterDatabase` 解析。

---

## 匯入後工作流程

```
Obsidian 寫作 (Windows)
    ↓ git push
docs/writing/ (本 repo)
    ↓ AI 批量對齊 id + frontmatter
docs/writing/ 定稿 md
    ↓ 手動或 AI 生成
data/story_events/*.tres + DialogueSequence
    ↓
python3 tools/run_all_sandboxes.py
```

目前 **沒有** md→tres 自動管線；對齊 md 是第一階段，生成 `.tres` 是第二階段（可請 AI 協助）。

---

## 給 AI 批量對齊時請提供

1. 整個 `01_Characters/`、`02_Story_Events/`、`plots/`（zip 或 push 到可讀 repo）
2. [`CHARACTER_REGISTRY.md`](CHARACTER_REGISTRY.md)（已在本 repo）
3. 若有 **暱稱→id 對照表**（Excel/一頁 md），對齊更快

AI 會產出：補齊 frontmatter 的 md、更新 `CHARACTER_REGISTRY` 創作欄、列出待確認的模糊映射。

---

## 本 repo 現有示例（可對照格式）

| 檔案 | 說明 |
|------|------|
| `scripts/story_meeting_first_session_01.md` | 首次周會 frontmatter 範例 |
| `scripts/story_meeting_weekly_flavor_01.md` | 重複周會 + cooldown 範例 |
| `CHARACTER_REGISTRY.md` | 16 藝人 + 10 rival + NPC 登記 |

> 匯入完成後，可把 `scripts/` 下示例 **搬進** `02_Story_Events/` 對應子目錄，再刪除舊 `scripts/` 避免重複。

---

## 下一步（勇者大人可選）

1. **方案 A**：把 GitHub 內容 push 到 `docs/writing/`，告訴我「開始對齊」。
2. 在本機 clone 私有 repo 到 workspace，我直接讀檔批量改。
3. 先只貼 `01_Characters` 或 `plots/start_flow.md` 試跑一輪對齊示範。
