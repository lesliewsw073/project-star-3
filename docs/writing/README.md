# 寫作資料區（Obsidian / GitHub 同步）

> **全局 spec 不在此目錄。** 唯一真相来源：  
> `/Users/luke/Desktop/docs/项目梳理_明星志愿3精神续作.md`  
> 专项：[`剧本人设写作规范.md`](file:///Users/luke/Desktop/docs/剧本人设写作规范.md) · [`图片规格与尺寸.md`](file:///Users/luke/Desktop/docs/图片规格与尺寸.md)  
> 本目录为 vault **镜像**；改动请先更新桌面 master，再同步至此。

本目錄供 **人設、劇本、事件大綱** 等創意文本使用，與 Godot 的 `data/` 資源分開管理。

- 創意內容：在此自由撰寫
- 程式引用：匯入遊戲時對齊 `CHARACTER_REGISTRY.md` 中的 **id** 與欄位
- 對齊協助：寫完後可將原文交給 AI，批量修正 id、變數占位、養成修正欄位

---

## 目錄結構（建議）

```
docs/writing/
├── README.md                 ← 本說明（含程式查閱、沙盒）
├── 00_Project_Spec/          ← 專案 spec、開局流程、event 格式（2026-06-19）
├── README_IMPORT.md          ← MyIdolGameScript 匯入對照（GitHub 劇本 repo）
├── CHARACTER_REGISTRY.md     ← 角色 ID 主表（最重要）
├── README_STORY.md           ← 劇本／事件 event_id、frontmatter、Obsidian 對齊
├── README_ITEMS.md           ← 道具／貨幣／物品欄規範
├── 01_Characters/            ← 人設（對齊 MyIdolGameScript / Obsidian）
├── 02_Story_Events/          ← 劇本 vault 核心（Obsidian 主目錄）
├── 04_Characters_image/      ← vault 參考圖（正式資產見 assets/characters/）
├── plots/                    ← 流程大綱（如 start_flow.md）
├── characters/               ← （舊）可併入 01_Characters
└── scripts/                  ← （舊）示例；新劇本請放 02_Story_Events
```

Obsidian vault 可直接指向 `docs/writing/`，或把此資料夾複製到 Windows 上的 vault，再透過 GitHub 同步回來。

---

## 核心規則（3 條）

1. **id 是主鍵，顯示名可以改。** 劇本裡引用角色時用 id，不要只用暱稱。
2. **主角姓名用變數，不要硬寫。** 例如 `{player_address}`，不要寫死「陸星河」。
3. **我方 16 藝人的養成修正（8 欄）**在 Godot `.tres` 手動填（見 `CHARACTER_REGISTRY.md` 與 `00_Project_Spec/项目梳理_明星志愿3精神续作.md` §0.5 H），人設 md 可寫折疊 callout 備註，但不進程式 YAML。

---

## 角色人設模板

複製到新檔案，例如 `characters/artist_001.md`：

```yaml
---
id: artist_001
type: artist          # protagonist | secretary | artist | npc
display_name: （待定）
gender: female        # male | female
# 養成修正（contract_diff_mod 等）在 godot_resource 的 .tres 填，不在此 YAML
opening_pick: true    # 是否為開局三選一候選
status: draft         # draft | review | locked
godot_resource: res://data/artists/artist_001/artist_001.tres
---

## 一句話

## 外貌 / 氣質

## 性格與口癖

## 背景

## 與主角的關係起點

## 備註（不進遊戲，僅創作參考）
```

---

## 對話劇本模板

> **完整規範**（`event_id` 命名、`story_channel`、`meeting_scope`、Obsidian frontmatter）见 [`README_STORY.md`](README_STORY.md)。

複製到新檔案，例如 `scripts/story_follow_gig_bar_01.md`：

```yaml
---
event_id: story_follow_gig_bar_01
event_title: 酒吧駐唱後台
character_id: artist_001       # 好感主要對象；並列事件可留空
trigger_context: follow        # follow | visit | meeting | manual
trigger_mode: solo             # solo | parallel
task_signature: gig:gig_bar_singer_01
location_id:                   # 探望用，如 screen_2
facility_id:                   # 探望用，如 fac_bar
affection_delta: 3
status: draft
godot_resource:                # 匯入後填，如 res://data/story_events/...
---

## 場景描述

（給自己看的舞台說明，不直接進遊戲）

## 對話

| speaker_id | speaker_name | text |
|------------|--------------|------|
| artist_001 | （顯示名） | {player_address}，今天的駐唱還順利嗎？ |
| protagonist | （主角） | 還行，觀眾反應不錯。 |
| artist_001 | （顯示名） | 那就好。下週還有一場，記得幫我排開。 |
```

也可用條列式（二選一即可）：

```markdown
- speaker_id: artist_001
  speaker_name: （顯示名）
  text: "{player_address}，今天的駐唱還順利嗎？"
```

---

## 對話變數（劇本中可直接使用）

| 占位符 | 說明 |
|--------|------|
| `{player_full_name}` | 主角全名（玩家自訂） |
| `{player_last_name}` / `{player_first_name}` | 姓 / 名 |
| `{player_title}` | 預設職稱「製作人」 |
| `{player_formal_title}` | 姓 + 職稱，如「陸製作人」 |
| `{player_address}` | 依 **當前說話人** 對主角好感自動稱呼 |
| `{company_name}` | 玩家公司名 |
| `{agency_name}` | 上下文藝人的所屬**經紀公司**名（`agency_*`）；未設定則空 |
| `{publisher_name}` / `{job_company_name}` | 通告／製作方（`comp_*`）顯示名 |
| `{player_agency_id}` | 固定 `agency_player` |
| `{relationship_level}` | 當前說話人與主角的關係等級名 |
| `{relationship_affection}` | 當前好感數值 |
| `{npc_name}` | 當前說話 NPC 的顯示名（`npc_*`） |
| `{artist_name}` | 當前說話藝人的顯示名（`artist_*`） |

> `speaker_id` 填對，`{player_address}` 等才會依該角色好感解析。主角台詞的 `speaker_id` 填 `protagonist` 或留空。

---

## ID 命名規則

| 類型 | 格式 | 範例 |
|------|------|------|
| 主角 | 固定 | `protagonist` |
| 秘書 | 固定 | `secretary` |
| 藝人 | `artist_NNN` | `artist_001` |
| 競爭對手 | `rival_NNN` | `rival_001` |
| 劇情 NPC | `npc_{角色}_{NN}` | `npc_shopkeeper_01` |
| 經紀公司 | `agency_*` | `agency_001` |
| 通告公司 | `comp_*` | `comp_film_01` |
| 互動事件 | 自訂，全專案唯一 | `story_follow_gig_bar_01` |
| 跟隨觸發任務 | `gig:{gig_id}` 等 | `gig:gig_bar_singer_01` |

新增藝人：下一個可用序號 + 對應 `data/artists/artist_XXX/` 資料夾。  
新增 NPC：下一個可用序號 + 對應 `data/npcs/{資料夾名}/`。

---

## 匯入 Godot 時的對應

| 寫作內容 | 遊戲資源 |
|----------|----------|
| 藝人人設 + 數值 | `data/artists/.../artist_XXX.tres` |
| NPC 人設 | `data/npcs/.../npc_XXX.tres` |
| 對話 | `DialogueSequence`（`.tres`） |
| 跟隨 / 探望 / 互動 | `data/story_events/*.tres` |

目前 **沒有** Markdown 自動匯入管線；對齊後需手動或請 AI 協助生成 `.tres`。

---

## 程式 .gd 查閱（藝人／公司／NPC／通告）

寫作對齊 id 後，若要自己看程式接線，可按領域查下列檔案。

### 建議閱讀順序

1. `scripts/autoload/CharacterDatabase.gd`
2. `ArtistManager.gd` → `Artist_Resource.gd`
3. `AgencyDatabase.gd` → `CompanyDatabase.gd`
4. `NpcManager.gd` → `NPCResource.gd` → `SecretaryManager.gd`
5. `JobManager.gd` → `JobResource.gd` → `GigManager.gd`
6. `DialogueVariableResolver.gd`
7. `GameRootController.gd`（主流程，較長）

### 藝人

| 檔案 | 職責 |
|------|------|
| `ArtistManager.gd` | 載入、簽約／解約、roster、劇情 gate |
| `RivalManager.gd` | `rival_*` 競爭對手 |
| `Artist_Resource.gd` / `ArtistProfileResource.gd` | 靜態圖紙、人設檔 |
| `ArtistInstance.gd` | 已簽約運行時 |
| `ArtistHealthComponent.gd` / `ArtistMoodComponent.gd` | 疲勞、壓力 |
| `Artist_Resource.gd`「養成修正」 | 簽約／失敗／完美／道德／好感／壓力／疲勞／滿意度倍率 |

### 公司

| 檔案 | 職責 |
|------|------|
| `AgencyDatabase.gd` | 經紀 `agency_*`（可簽約） |
| `CompanyDatabase.gd` | 通告製作 `comp_*`（不可簽約） |
| `PlayerManager.gd` | 玩家公司名 |
| `FacilityResource.gd` | 設施 `linked_company_id` |

### NPC

| 檔案 | 職責 |
|------|------|
| `NpcManager.gd` | 劇情 `npc_*` |
| `SecretaryManager.gd` | 秘書 `secretary` |
| `NPCResource.gd` | NPC 靜態資料 |
| `FacilityPanel.gd` / `dialogue_panel.gd` | 設施對話、頭像 |

### 通告／打工

| 檔案 | 職責 |
|------|------|
| `JobManager.gd` / `JobResource.gd` / `JobInstance.gd` | 通告全流程 |
| `GigManager.gd` / `GigResource.gd` | 打工 |
| `ScheduleManager.gd` / `SchedulePickerManager.gd` | 行程排程 |
| `FollowPlanManager.gd` / `StoryTriggerManager.gd` | 跟隨、探望劇情 |
| `DayWorkReportPanel.gd` / `DayWorkReportBuilder.gd` | 工作日報 |
| `SaveManager.gd` | 通告存檔 |

---

## 沙盒驗證

領域相關沙盒位於 `tools/`，最後執行 **2026-06-18，全部通過**。

```bash
python3 tools/run_all_sandboxes.py
```

| 沙盒 | 領域 |
|------|------|
| `artist_profile_sandbox.py` | 藝人檔案、UI、16 份 `.tres` |
| `character_database_sandbox.py` | 16 我方 + 10 rival + 角色中樞 |
| `agency_database_sandbox.py` | 經紀 + 通告公司 API |
| `npc_database_sandbox.py` | NpcManager、設施 NPC |
| `follow_story_sandbox.py` | 跟隨／探望（`gig:*` / `job:*`） |
| `save_v1_sandbox.py` | 通告存檔 |
| `maphub_ui_sandbox.py` | 地圖、NPC、開局簽約 UI |
| `schedule_flow_sandbox.py` | 行程 ↔ 通告／打工 |
| `follow_plan_sandbox.py` | 跟隨合併 |
| `day_cycle_sandbox.py` | 日循環 |
| `story_event_sandbox.py` | 劇本事件 schema、命名、SIGN/MEETING 占位 |
| `item_system_sandbox.py` | 道具四大類、口碑、公司物品边际、物品欄 |

> 尚無獨立 `JobManager` / `GigManager` 專項沙盒；通告邏輯分散在上述腳本中。

---

## Obsidian 同步建議

- 筆記放在 `docs/writing/` 下，GitHub 同步即可跨 Windows / macOS
- 可忽略 Obsidian 本地設定：`.obsidian/workspace.json`、`.obsidian/workspace-mobile.json`
- 避免在遊戲台詞中使用 `[[WikiLink]]`；若要用 Obsidian 連結，僅限創作備註區
