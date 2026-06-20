# Project Star 3 開發進度交接

更新時間：2026-06-18（新聞系統 Phase 1、對話 UI 改版、米语 CG、角色圖首批投放）

專案路徑：`/Users/luke/project-star-3`  
主場景：`GameRoot.tscn`（遊戲視窗 **1600×900**，`project.godot`）  
Godot：4.x  

**寫作與登記（企劃必讀）**

| 文件 | 用途 |
|------|------|
| `docs/writing/CHARACTER_REGISTRY.md` | 角色／事件／通告 id **唯一真相來源** |
| `docs/writing/README_STORY.md` | 劇本 frontmatter、`event_id` 命名 |
| `docs/writing/README_CHARACTER_ASSETS.md` | 圖片規格與目錄（頭像／立繪／CG）；匯入見 `PROJECT_PROGRESS.md` §1.9 |
| `docs/writing/README_IMPORT.md` | Obsidian ↔ Godot 匯入流程 |
| `docs/writing/CONTENT_TIER_REGISTRY.md` | 【測試】vs 正式內容分級 |

**全局唯一 spec（勇者大人定案 · 必讀）**

| 文件 | 路径 |
|------|------|
| 总 spec | `/Users/luke/Desktop/docs/项目梳理_明星志愿3精神续作.md` |
| 剧本人设 | `/Users/luke/Desktop/docs/剧本人设写作规范.md` |
| 图片规格 | `/Users/luke/Desktop/docs/图片规格与尺寸.md` |

`docs/writing/` 为 vault 镜像；**任何改动先更新桌面三份**，再改代码。详见 `.cursor/rules/desktop-canonical-spec.mdc`。

---

## ⚠️ 交接硬規則

- **每一次回答開頭必須稱呼使用者為「勇者大人」**
- 回答使用繁體中文；不擅自 commit
- 重要改動後跑 `python3 tools/run_all_sandboxes.py`（**25 項，應全綠**）

---

## 給下一個 AI 的第一句話模板

> 勇者大人，我已讀完 `PROJECT_PROGRESS.md` 與桌面 **`/Users/luke/Desktop/docs/项目梳理_明星志愿3精神续作.md`**（剧本人设/图片见同目录两份专项 md）。任何定案以桌面三份为准。

---

## 專案現況摘要

| 領域 | 狀態 |
|------|------|
| 日循環 / 大地圖 / Save v1（5 手動槽 + 2 自動槽） | ✅ |
| 角色中樞 16 artist + 10 rival + NPC | ✅ id／資料夾／圖片夾三層對齊 |
| 角色視覺（avatar／portrait／cg 三夾） | ✅ 001～003、006～008、店長已投放 PNG；003 CG `sign_knock_office` |
| 新聞系統 Phase 1 | ✅ 記者、每日頭條、進圖前彈窗；獎項全局占位 |
| 對話 UI `dialogue_panel` | ✅ 居中固定框、左／右立繪、名字條、22px 正文 |
| 劇情 SIGN／MEETING／FOLLOW／VISIT | ✅ 11 則 `.tres`；003 簽約→敲門→首日 office 含 CG |
| 通告 `target_company_id` ↔ 拍攝設施 | ✅ 4 則測試通告已三角對齊 |
| 課程開局解鎖 + 排程 UI 統一 | ✅ `course_acting_basic_01` |
| 道具／貨幣 Phase 0 | ✅ 週會送禮已接物品欄 |
| 邀請接案 UI | ✅ |
| 007～016 人設正文 / 設施 NPC 擴充 | ⚠️ 待填 |

---

# 圖片與劇本存放規範（詳盡定案）

> **核心原則：寫作與執行分軌。**  
> - **劇本文字** → `docs/writing/`（Obsidian，給人讀、給 AI 對齊）  
> - **劇本執行** → `data/story_events/*.tres`（Godot，給程式讀）  
> - **圖片資產** → **只**放 `assets/characters/`（不進 `docs/writing/`）

---

## 一、圖片存放邏輯與規則

### 1.1 總目錄與分桶（bucket）

所有可對話角色的視覺資源統一在：

```text
assets/characters/
├── artists/artist_NNN/     ← 我方藝人 artist_001～016
├── rivals/rival_NNN/       ← 競爭對手 rival_001～010
└── npcs/{邏輯id}/          ← 秘書 secretary、劇情 NPC npc_shopkeeper_01 …
```

**程式解析**：`CharacterVisualPaths.gd`  
- `artist_*` → bucket `artists`  
- `rival_*` → bucket `rivals`  
- 其餘（含 `secretary`、`npc_*`）→ bucket `npcs`

**禁止使用的舊路徑**（已刪除，勿再建立）：

- `assets/characters/portraits/`（複數）
- `assets/characters/imported/`
- `assets/characters/npcs/shopkeeper/`（已改 `npc_shopkeeper_01`）
- 任意 `{id}/avatars/`（複數，應為 `avatar/`）

### 1.2 每人三子夾（固定結構）

每位角色**必須**具備三個子目錄（可為空，僅放 `.gitkeep`）：

```text
{id}/
├── avatar/     ← 小頭像（列表、存檔槽、排程表）
├── portrait/   ← 半身透明立繪（對話：其他角色**左**、主角**右**）
└── cg/         ← 劇情 CG（全螢幕背景，可多張）
```

### 1.3 檔名規則（硬對齊邏輯 id）

| 類型 | 檔名公式 | 範例 |
|------|----------|------|
| 頭像 | `{id}_avatar.png` | `artist_003_avatar.png` |
| 立繪 | `{id}_portrait.png` | `secretary_portrait.png` |
| CG | `{id}_cg_{場景key}.png` | `artist_003_cg_meeting_cake.png` |

- `{id}` **必須**與 `CHARACTER_REGISTRY`、`.tres` 的 `artist_id`／`npc_id`、劇本 `speaker_id` **完全一致**。
- CG 的 `{場景key}` 由企劃自訂（建議 snake_case）；劇本事件欄位 `cg_id` **只填 key**，不填路徑。

**CG 路徑解析範例**（owner=`artist_003`，cg_id=`meeting_cake`）：

```text
res://assets/characters/artists/artist_003/cg/artist_003_cg_meeting_cake.png
```

### 1.4 畫布規格（重新出圖請遵守）

| 類型 | 畫布 | 格式 | 單檔建議 | 遊戲內用途 |
|------|------|------|----------|------------|
| avatar | **512×512** | PNG 透明 | ≤ 500 KB | 44～112 px 方塊縮放 |
| portrait | **900×1400** | PNG RGBA 透明 | 1～3 MB | 對話左側約 420×700 |
| cg | **1600×900** | PNG/JPG | JPG ≤1.5 MB | 全螢幕背景，對話照常進行 |

**CG 顯示層級**：底層 CG → 半透明遮罩（有 CG 時較淡）→ **左／右立繪**（遮罩之上）→ 居中對話框 + 名字條。

### 1.5 邏輯 id ↔ 圖片夾 ↔ 資料 `.tres` 對照表

| 類型 | 邏輯 id | 圖片根目錄 | 資料 `.tres` |
|------|---------|------------|--------------|
| 我方藝人 | `artist_NNN` | `assets/characters/artists/artist_NNN/` | `data/artists/artist_NNN/artist_NNN.tres` |
| 競爭對手 | `rival_NNN` | `assets/characters/rivals/rival_NNN/` | `data/rivals/rival_NNN/rival_NNN.tres` |
| 秘書 | `secretary` | `assets/characters/npcs/secretary/` | `data/npcs/secretary/npc_secretary.tres` |
| 劇情 NPC | `npc_shopkeeper_01` | `assets/characters/npcs/npc_shopkeeper_01/` | `data/npcs/npc_shopkeeper_01/npc_shopkeeper_01.tres` |
| 記者（特殊 NPC） | `reporter_01`／`reporter_02` | `assets/characters/npcs/reporter_01/` 等 | `ReporterManager`（不走 NpcManager） |

**例外（僅秘書）**：邏輯 id 是 `secretary`（不是 `npc_secretary_01`）；資料夾仍叫 `secretary/`。  
**劇情 NPC**：資料夾名 = 邏輯 id（例 `npc_shopkeeper_01/`，不是 `shopkeeper/`）。

### 1.6 `.tres` 與自動載入

- `ArtistResource`／`NPCResource` 的 `avatar`／`portrait` 欄位**可留空**。
- 留空時 `CharacterDatabase.get_avatar()`／`get_portrait()` 依 `CharacterVisualPaths` **自動掃標準檔名**。
- 手動在 `.tres` 掛載 Texture 可覆寫自動路徑（少用，除非特殊裁切版）。

### 1.7 企劃工作流（MyIdolGameScript → 本專案）

```text
04_Characters_Image/（外部 AI 素材，通常白底）
    ↓ 依 id 命名
cursor_png/{id}.png
    ↓ 批次腳本（見 §1.9）
cursor_png/processed/{avatar,portrait}/{id}_avatar.png、{id}_portrait.png
    ↓ 人工確認構圖後複製
assets/characters/{bucket}/{id}/{avatar,portrait,cg}/
    ↓ Godot 自動 import
遊戲內顯示（無需改程式）
```

人設長文（不含大圖）放：`docs/writing/01_Characters/artist_NNN.md`  
人設 md 的 `portrait:` 欄填**相對路徑字串**（給企劃對照），例：

```text
portrait: assets/characters/artists/artist_003/portrait/artist_003_portrait.png
```

### 1.9 頭像／立繪批次產出（`cursor_png` 管線 · 定案）

> **腳本唯一入口**：`tools/image_tools/process_character_exports.py`  
> **頭像與立繪規則分開**——勿把立繪的「全身 82% 身高」套到頭像；頭像只做「上方半身放大 + 留邊」。

#### 1.9.1 目錄與檔名

| 階段 | 路徑 | 說明 |
|------|------|------|
| 原圖（輸入） | `cursor_png/{id}.png` | 僅根目錄；例 `artist_001.png`、`npc_shopkeeper_01.png` |
| 批次產出 | `cursor_png/processed/avatar/{id}_avatar.png` | 512×512 RGBA 透明 |
| 批次產出 | `cursor_png/processed/portrait/{id}_portrait.png` | 900×1400 RGBA 透明 |
| 遊戲正式 | `assets/characters/{bucket}/{id}/avatar/`、`portrait/` | 確認後**手動複製**（檔名不變） |

`{id}` 必須與 `CHARACTER_REGISTRY` 邏輯 id 一致。CG（1600×900）**不在此腳本處理**，企劃自行出圖放入 `cg/`。

#### 1.9.2 環境與執行

```bash
cd /Users/luke/project-star-3/tools/image_tools
source env.sh                    # 可選：PATH 含 pngquant / optipng
.venv/bin/python process_character_exports.py
```

**依賴**（已建 venv：`tools/image_tools/.venv`）：

| 套件／工具 | 用途 |
|------------|------|
| Pillow、numpy、opencv-python-headless | 去背、裁切、縮放 |
| Homebrew `pngquant`、`optipng` | 僅 **avatar** 壓縮（portrait 不跑 pngquant） |

首次建環境：`python3 -m venv .venv && .venv/bin/pip install -r requirements.txt`

#### 1.9.3 去背（avatar／portrait 共用前處理）

- 四角泛洪去除 `#FFFFFF` 白底（`tolerance=28`）
- **保留**制服白條等「內部白色」（非邊緣連通白底）
- 貼近背景的半透明像素一併清除 → 輸出 RGBA 透明 PNG

#### 1.9.4 頭像規則（`make_avatar` · 與立繪不同）

| 步驟 | 參數 | 說明 |
|------|------|------|
| 裁切 | `AVATAR_HEAD_CROP_HEIGHT_RATIO = 0.50` | 取去背 bbox **上方 50%** 裁成**正方形**（水平置中 bbox） |
| 縮放 | `AVATAR_MARGIN_RATIO = 0.07` | 等比放大至 512×512，四周留 **7%** 透明邊距 |
| 原則 | — | 頭部接近填滿、**不貼邊、不裁髮頂／帽子**；略偏左／右可後調 |
| 水平微調 | `AVATAR_HORIZONTAL_OFFSET[id]` | 正數＝右移，負數＝左移（像素） |

**目前已調整**（2026-06-18）：

```python
AVATAR_HORIZONTAL_OFFSET = {
    "artist_001": 48,           # 吉他拉偏視覺 → 右移
    "artist_006": -38,
    "artist_007": -16,
    "npc_shopkeeper_01": -40,
}
```

#### 1.9.5 立繪規則（`make_portrait` · 全身構圖）

| 步驟 | 參數 | 說明 |
|------|------|------|
| 縮放 | `PORTRAIT_BODY_HEIGHT_RATIO = 0.82` | 人物高度 = 畫布高 × **82%** |
| 對齊 | `PORTRAIT_BOTTOM_MARGIN_RATIO = 0.05` | 腳底／底邊距 = 畫布高 × **5%** |
| 水平 | 預設置中 | 寬圖左緣被裁時用 `PORTRAIT_HORIZONTAL_OFFSET` |
| 微調 | `artist_001: 50` | 正數＝整體**右移**（露出左側吉他） |

畫布固定 **900×1400**；**不跑 pngquant**（保透明與細節）。

#### 1.9.6 後處理與禁止事項

| 類型 | 後處理 |
|------|--------|
| avatar | `pngquant`（quality 70–92）+ `optipng -o5` |
| portrait | 無（直接存 PNG） |

**勿用**（已試驗、品質不符企劃要求）：

- `process_pixel_hd.py`、`process_pixel_style_compare.py` 等腳本批量「像素化」
- 以腳本降採樣冒充手繪／Nano Banana 級像素插畫

新增角色：原圖放入 `cursor_png/` → 跑腳本 → 目視確認 → 複製至 `assets/characters/…` → Godot 重新 import。

**已投放 PNG（2026-06-18）**：`artist_001`、`002`、`003`、`006`、`007`、`008`、`npc_shopkeeper_01`（avatar + portrait）；米语 CG `artist_003_cg_sign_knock_office.png` → `cg/sign_knock_office`。

#### 1.9.7 新增／調整構圖時改哪裡

| 需求 | 修改位置 |
|------|----------|
| 頭像留邊、裁切高度 | `process_character_exports.py` → `AVATAR_MARGIN_RATIO`、`AVATAR_HEAD_CROP_HEIGHT_RATIO` |
| 某角色頭像左／右移 | 同上 → `AVATAR_HORIZONTAL_OFFSET` |
| 立繪身高、底邊距 | 同上 → `PORTRAIT_BODY_HEIGHT_RATIO`、`PORTRAIT_BOTTOM_MARGIN_RATIO` |
| 立繪水平（吉他等） | 同上 → `PORTRAIT_HORIZONTAL_OFFSET` |

### 1.10 圖片相關沙盒

```bash
python3 tools/character_assets_sandbox.py   # 目錄結構、規格說明
python3 tools/id_alignment_sandbox.py       # id ↔ 資料夾 ↔ 劇本欄位
```

---

## 二、劇本存放邏輯與規則

### 2.1 雙軌：寫作 md vs 執行 tres

| 層級 | 路徑 | 格式 | 主鍵 | 誰維護 |
|------|------|------|------|--------|
| **寫作層** | `docs/writing/02_Story_Events/` | Markdown + YAML frontmatter | `event_id`（frontmatter） | 企劃／Obsidian |
| **執行層** | `data/story_events/` | `InteractionEventResource` `.tres` | `event_id`（資源欄位） | 匯入後手動或 AI 生成 |
| **流程大綱** | `docs/writing/plots/` | Markdown | — | 企劃，不進 Godot |
| **會議示例** | `docs/writing/scripts/` | Markdown | — | 可併入 `02_Story_Events/` |

**鐵律**：程式只認 `event_id`，**不認檔名**。檔名建議與通道一致以利搜尋，但非必須。

**目前無 md→tres 自動管線**；標準流程：

```text
Obsidian 寫 md + frontmatter
    ↓ AI／人工對齊 id
docs/writing/ 定稿
    ↓ 第二階段：生成或手改
data/story_events/*.tres
    ↓
python3 tools/story_event_sandbox.py
python3 tools/run_all_sandboxes.py
```

### 2.2 Obsidian 目錄結構（寫作層 · 2026-06-19 定案）

> 詳細規範：`docs/writing/00_Project_Spec/剧本event正文格式标准.md`

```text
docs/writing/
├── 00_Project_Spec/            # 專案 spec、開局流程、event 格式標準
├── 01_Characters/              # 人設長文（非劇本卡）
├── 02_Story_Events/
│   ├── 1_Main_Story/
│   │   ├── Artists/artist_NNN/     # sign、首次例會、主線、結局
│   │   └── Npcs/npc_shopkeeper_01/
│   ├── 2_Daily_Loops/
│   │   ├── Artists/
│   │   │   ├── Meeting_Weekly/artist_NNN/
│   │   │   ├── Schedule_Result/artist_NNN/{fail|success|perfect}/
│   │   │   ├── Visit_Flavor/artist_NNN/       # 拍攝期探班
│   │   │   ├── Map_Encounters/artist_NNN/     # 大地圖偶遇
│   │   │   ├── Hospital/ · Award_Speech/
│   │   │   # 無 Follow_Flavor（follow 僅觸發綁定 event）
│   │   └── Npcs/npc_shopkeeper_01/{enter|purchase_leave|leave_empty}/
│   ├── 3_Cross_Interactions/Duo/ · Ensemble/
│   ├── 4_Protagonist/
│   └── 5_Secretary/
├── plots/                      # start_flow.md 等流程大綱
└── scripts/                    # （舊）占位示例；新劇本請放 02_Story_Events
```

### 2.3 Godot 劇本目錄結構（執行層）

```text
data/story_events/
├── main/
│   ├── artist_001/00_first_meeting_sign.tres
│   ├── artist_002/00_first_meeting_sign.tres
│   └── artist_003/
│       ├── 00_first_meeting_sign.tres
│       ├── 01_day1_office.tres
│       └── 02_first_sunday_welcome.tres
├── meeting/
│   ├── 00_first_session.tres      # story_meeting_first_session_01
│   └── 01_weekly_flavor.tres        # story_meeting_weekly_flavor_01
├── follow_gig_bar_singer_01.tres    # event_id: story_follow_gig_bar_01
├── follow_gig_bar_parallel.tres
├── visit_bar_gig_01.tres            # event_id: story_visit_bar_gig_01
└── visit_tv_variety_01.tres
```

**路徑對齊規則**：`main/artist_NNN/` 內事件的 `owner` 與 `character_id` **必須**為 `artist_NNN`（與資料夾名一致）。

### 2.4 `event_id` 命名（全局唯一）

```text
story_{通道}_{主體或場景}_{序號}
```

| 通道 key | story_channel | 範例 |
|----------|---------------|------|
| `sign` | SIGN | `story_sign_artist_003_first_meeting` |
| `meeting` | MEETING | `story_meeting_first_session_01` |
| `calendar` | CALENDAR | `story_main_artist_003_day1_office_01` |
| `follow` | FOLLOW | `story_follow_gig_bar_01` |
| `visit` | VISIT | `story_visit_tv_variety_01` |

**硬性規則**：

1. 全小寫、底線；**全局唯一**（`StoryTriggerManager` 掃描註冊）。
2. 角色引用用程式 id：`artist_001`，禁止「一号」「001」省略前綴。
3. **follow ⊥ visit**：同一劇情若兩邊都要，拆成兩張卡、兩個 `event_id`。
4. 雙人線：`owner: duo:artist_004+artist_005`，稿存 `3_Cross_Interactions/Duo/` **一份**。
5. 測試內容：`is_test_content = true`，標題加【測試】（見 `CONTENT_TIER_REGISTRY.md`）。

### 2.5 frontmatter 必填欄位（寫作 md）

```yaml
---
event_id: story_sign_artist_003_first_meeting
event_title: 米语签约首次相遇
arc_type: first_meeting
owner: artist_003
story_channel: sign
participants: [artist_003]
character_id: artist_003       # 好感結算主對象
execute_once: true
blocking: true
affection_settlement: once     # none | once | per_line
affection_delta: 5
cg_id:                         # 可選；填 CG 場景 key，見 §1.3
priority: 100
required_flags: {}
sets_flags:
  first_meeting.artist_003_done: true
godot_resource: res://data/story_events/main/artist_003/00_first_meeting_sign.tres
status: draft                  # draft | in_game
---
```

**`godot_resource`**：指向執行層 `.tres`；AI 對齊時須驗證該路徑**存在**。

### 2.6 對話正文格式（md 表格）

```markdown
| speaker_id | speaker_name | text |
|------------|--------------|------|
| artist_003 | | {player_address}，合同我签好了。 |
| protagonist | | 欢迎加入。 |
| secretary | 小唯 | 制作人，本週的週日會議開始了。 |
```

- `speaker_id`：**必須**是 `CHARACTER_REGISTRY` 已登記 id。
- `speaker_name` 可留空 → 運行時 `CharacterDatabase.get_display_name()`。
- 製作人稱呼用變數：`{player_address}`、`{player_full_name}`、`{company_name}` 等。

### 2.7 通道專用欄位

| 通道 | 額外欄位 | 說明 |
|------|----------|------|
| `meeting` | `meeting_scope: first \| weekly` | 首次週日會議 vs 常規週會 |
| `follow` | `task_signature: gig:gig_bar_singer_01` | 跟隨日匹配行程簽名 |
| `visit` | `task_signature` + `location_id` + `facility_id` | 探班匹配地圖設施 |
| `sign` | `owner` = 簽約藝人 id | 開局三選一後觸發 |

**task_signature 格式**：`gig:{gig_id}`、`job:{job_id}`、`course:{course_id}`（與 `FollowPlanManager` 一致）。

### 2.8 內容分級（測試 vs 正式）

| 級別 | 規則 |
|------|------|
| 正式 | 目前僅 **米语主線** + **秘書小唯**；`is_test_content = false` |
| 測試 | 其餘占位；`is_test_content = true` + 標題【測試】 |

登記表：`docs/writing/CONTENT_TIER_REGISTRY.md`

### 2.9 劇本相關沙盒

```bash
python3 tools/story_event_sandbox.py
python3 tools/artist_003_opening_flow_sandbox.py
python3 tools/follow_story_sandbox.py
python3 tools/id_alignment_sandbox.py
```

---

## 三、通告／公司／行程 id 對齊（2026-06-18 已修）

### 3.1 兩套「公司」不可混用

| 前綴 | 用途 | 範例 |
|------|------|------|
| `agency_*` | 經紀公司（可簽約） | `agency_player`、`agency_001` |
| `comp_*` | 通告／製作方（不可簽約） | `comp_tv_01` 草莓衛視 |

### 3.2 通告三角對齊（測試 job 已統一）

每則 `JobResource` 應滿足：

```text
target_company_id  ==  unlock_facility.linked_company_id
unlock_location_id ==  設施所在 screen_N
```

| job_id | 發布方 | 拍攝設施 |
|--------|--------|----------|
| `test_job_tv_variety_01` | `comp_tv_01` | `fac_tv_01` / screen_2 |
| `test_job_ad_shoot_01` | `comp_ad_01` | `fac_ad_01` / screen_1 |
| `test_job_movie_short_01` | `comp_film_01` | `fac_film_01` / screen_3 |
| `test_job_music_solo_01` | `comp_music_01` | `fac_music_01` / screen_2 |

### 3.3 課程／打工解鎖

| 類型 | 開局解鎖 | 管理器 |
|------|----------|--------|
| 打工 | `gig_bar_singer_01` | `GigManager.INITIAL_UNLOCKED_GIG_IDS` |
| 課程 | `course_acting_basic_01` | `CourseManager.INITIAL_UNLOCKED_COURSE_IDS` |

排程 UI（`SchedulePickerManager` 與週會 `GameRootController`）**統一**使用 `get_unlocked_gigs()`／`get_unlocked_courses()`。

### 3.4 行程存檔 `task_ref`（Save v1）

| kind | id 來源 |
|------|---------|
| `gig` | `gig_bar_singer_01` |
| `course` | `course_acting_basic_01` |
| `vacation` | `vacation_domestic_spring_01` |
| `job_instance` | 執行期 `JobManager` 產生 |

### 3.5 藝人／通告新欄位（新聞系統用）

| 欄位 | 資源 | 說明 |
|------|------|------|
| `is_debuted` | `ArtistResource` | 是否已出道；影響新聞選角與記者採訪 |
| `is_major_job` | `JobResource` | 重大通告；可觸發預熱／正面採訪（觸發邏輯待 Phase 2） |

---

## 八、新聞系統（Phase 1 · 2026-06-18）

### 8.1 企劃定案（部分待實作）

- **兩位記者**：`reporter_01`（狗仔，一次性劇情／CG）、`reporter_02`（正面記者，可重複，頒獎／重大通告）
- **每日頭條**：進大地圖前彈 `DailyNewsPanel` 一屏；九類新聞優先 1～8，剩餘填填充稿
- **正面採訪**（待 UI）：拒絕／秘書代訪（不增聲望口碑）／親自或帶藝人（增聲望口碑）
- **獎項**：`AwardRegistry` 全局占位，待填實表

### 8.2 已落地程式

| 項目 | 路徑 |
|------|------|
| `ReporterManager` | `scripts/autoload/ReporterManager.gd`（同秘書結構，不走 `NpcManager`） |
| 記者資料 | `data/npcs/reporter_01/`、`reporter_02/`（【測試】） |
| `AwardRegistry` | `scripts/autoload/AwardRegistry.gd` |
| `NewsEditionBuilder` | `scripts/news/NewsEditionBuilder.gd` |
| `NewsManager` 擴充 | 九類 `EditionType`、`build_daily_edition_for_today()` |
| `DailyNewsPanel` | `scripts/ui/DailyNewsPanel.gd` |
| 日循環閘門 | `GameFlowManager._try_begin_free_day_with_news()` → `daily_news_requested` → 關閉後 `enter_map()` |
| 填充模板 | `data/news/templates/test_filler_*.tres` |
| 存檔 | `SaveManager` 含 `news` 區塊 |

### 8.3 待做（Phase 2+）

狗仔 encounter 選項分支、正面記者採訪 UI、獎項表填實、重大通告預熱觸發、新聞大界面歷史回看。

```bash
python3 tools/news_system_sandbox.py
```

---

## 九、對話 UI（dialogue_panel · 2026-06-18）

**檔案**：`UI/dialogue_panel.tscn`、`scripts/controllers/dialogue_panel.gd`

| 規格 | 值 |
|------|-----|
| 對話框寬度 | **880px**，底部**水平居中** |
| 名字條 | 獨立 `NamePlate` 在對話框上方；字級 **28** |
| 正文 | 字級 **22**；`fit_content = false`（無立繪時不拉長） |
| 立繪 | **左** `PortraitLeftRect`：非主角；**右** `PortraitRightRect`：主角 `protagonist` |
| 層級 | CG → 半透明遮罩（有 CG 時 alpha **0.38**）→ 立繪 z=2 → 對話 UI z=3 |

**已移除**：`portrait_bust_rect`、對話框內動態 `AvatarRect`／`HBoxContainer`。

米语開局：`StoryBeatTransition.gd` 在 sign→office 敲門銜接時鋪 CG `sign_knock_office`。

---

## 四、沙盤與檢查（25 項）

```bash
python3 tools/run_all_sandboxes.py
```

| 沙盒 | 驗證 |
|------|------|
| `id_alignment_sandbox.py` | 角色 id、劇本路徑、圖片夾 |
| `job_facility_alignment_sandbox.py` | 通告↔公司↔設施、課程解鎖、task_signature |
| `character_assets_sandbox.py` | 三子夾結構、禁止 avatars/；允許已投放 PNG |
| `story_event_sandbox.py` | event_id 命名與 SIGN/MEETING |
| `news_system_sandbox.py` | 每日頭條、記者、存檔 news 區塊 |
| `save_slots_sandbox.py` | 5+2 存檔槽 |
| … | 其餘 20 項見 `tools/run_all_sandboxes.py` |

---

## 五、已知待辦

1. **007～016 人設正文** + `01_Characters/*.md`；004、005 等缺 avatar／portrait 需補圖
2. **設施 NPC**（酒吧、醫院、美術館）+ `npc_*` 資源
3. **劇本量產**：`02_Story_Events/` → `data/story_events/`
4. **artist_001/002 顯示名**：登記表 Yuka/Valeria vs `.tres` 一号/二号（擇一統一）
5. **`comp_film_03`** 補 `fac_film_03` 或標記占位
6. **新聞 Phase 2**：狗仔 encounter、正面採訪 UI、獎項表、重大通告預熱
7. 通告進行中畫面升級；口碑／聲望埋坑深化

---

## 六、Autoload 一覽

```
TimeManager, ArtistManager, RivalManager, NpcManager, CharacterDatabase
AgencyDatabase, CompanyDatabase, JobManager, CourseManager, GigManager
InteractionManager, StoryTriggerManager, StoryPlaybackController
NewsManager, ReporterManager, AwardRegistry, GameFlowManager, SecretaryManager, VacationManager
ItemDatabase, ItemManager, CompanyItemManager, PlayerHomeManager, InventoryManager
SaveManager, ScheduleManager, FollowPlanManager, SchedulePickerManager
ProtagonistManager, RelationshipManager, PlayerManager, DialogueVariableResolver
```

---

## 七、變更紀錄（近期）

| 日期 | 變更 |
|------|------|
| 2026-06-18 | **新聞系統 Phase 1**：記者、`DailyNewsPanel`、九類頭條、進圖前閘門；`is_debuted`／`is_major_job` |
| 2026-06-18 | **對話 UI 改版**：居中 880px、左／右立繪、名字條 28px、正文 22px |
| 2026-06-18 | **米语 CG** `sign_knock_office` + 開局敲門銜接；001～003、006～008、店長 PNG 投放 |
| 2026-06-18 | **頭像／立繪批次產出定案**：`cursor_png/` + `process_character_exports.py`；§1.9 詳述規則與 offset |
| 2026-06-18 | 角色視覺三夾重構；清空舊 PNG |
| 2026-06-18 | id 全對齊；`npc_shopkeeper_01` 資料夾統一 |
| 2026-06-18 | 簽約劇本檔 `00_first_meeting_sign.tres` |
| 2026-06-18 | 通告拍攝地與 comp 對齊；課程開局解鎖 |
| 2026-06-18 | 多槽存檔、邀請接案 UI、測試內容分級 |
| 2026-06-18 | `job_facility_alignment_sandbox`；沙盒增至 **25** 項 |

---

## 十、每日開發記錄（摘要）

> 完整逐日軌跡見桌面 `项目梳理_明星志愿3精神续作.md` §十一。以下僅列早期易混淆日期之修正。

| 日期 | 摘要 |
|------|------|
| 2026-06-11（四） | 立項；`Artist_Resource` 第一版 |
| 2026-06-12（五） | Gemini／手動：靜態 Resource、Instance、Health/Mood、`ArtistManager`／`PlayerManager` 雛形 |
| 2026-06-15（一） | **原誤併入 06-12**：大地圖→設施→NPC→對話鏈路、`FacilityPanel`／`dialogue_panel`、`CompanyDatabase`／`SecretaryManager` |
| 2026-06-16（二） | 系統骨架重整、19 屬性對齊、`TimeManager`／`GameFlowManager`／`ScheduleManager` |
| 2026-06-17（三） | 主循環、Save v1、三檔品質、UI 緊湊化 |
| 2026-06-18（四） | 角色中樞、劇本分類、新聞 Phase 1、對話 UI、視覺資產、米语 CG；25 沙盒全綠 |
