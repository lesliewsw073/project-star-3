# 角色 ID 登記表

> **唯一真相來源**：所有劇本、人設、事件 metadata 中的角色引用，必須與本表 **id** 欄一致。  
> **顯示名** 可隨創作修改；匯入 Godot 時寫入 `artist_name` / `npc_name` / `speaker_name`。  
> **程式中樞**：`CharacterDatabase`（類型／顯示名／初始好感）  
> **程式查閱、沙盒**：見 [`README.md`](README.md)

> 規範：`.cursor/rules/test-content-marking.mdc`  
> **內容分級（測試 vs 正式）**：[`CONTENT_TIER_REGISTRY.md`](CONTENT_TIER_REGISTRY.md)

最後同步專案：2026-06-18

---

## 程式中樞對照

| id 類型 | 管理器 | 資源類 | 資料目錄 |
|---------|--------|--------|----------|
| `protagonist` | `ProtagonistManager` | — | — |
| `secretary` | `SecretaryManager` | `NPCResource` | `data/npcs/secretary/` |
| `reporter_01` / `reporter_02` | `ReporterManager` | `NPCResource` | `data/npcs/reporter_01/`、`reporter_02/` |
| `artist_NNN` | `ArtistManager` | `ArtistResource` | `data/artists/` |
| `rival_NNN` | `RivalManager` | `ArtistResource` | `data/rivals/` |
| `npc_*` | `NpcManager` | `NPCResource` | `data/npcs/` |
| `agency_*` | `AgencyDatabase` | — | 程式內建表 |
| `comp_*` | `CompanyDatabase` | — | 程式內建表 |

統一入口：`CharacterDatabase.get_display_name()` / `get_portrait()` / `get_initial_affection()`

---

## 固定角色

| id | 類型 | 顯示名（遊戲內） | 初始好感 | 狀態 | 備註 |
|----|------|------------------|----------|------|------|
| `protagonist` | 主角 | （玩家自訂） | — | locked | `ProtagonistManager`；姓名 `{player_*}` |
| `secretary` | 秘書 | **小唯** | 10 | in_game | 邏輯 id 固定；創作顯示名小唯 |
| `reporter_01` | 記者（狗仔） | **狗仔記者** | — | test | `ReporterManager`；一次性劇情／醜聞線 |
| `reporter_02` | 記者（正面） | **正面記者** | — | test | `ReporterManager`；頒獎／重大通告採訪 |

### 秘書好感（硬性）

- **不可收禮**（道具／金幣／物品欄贈送皆禁止）。
- 好感僅能透過：**談話**、**獲獎**、**公司規模**里程碑、**特定劇情**提升。
- 程式：`ItemManager.try_gift_to_artist` 須拒絕 `secretary`；週會送禮 UI 僅限已簽約 `artist_*`。

---

## 經紀公司（AgencyDatabase）

> **僅經紀公司可簽約藝人。** 玩家公司邏輯 id 固定 `agency_player`，顯示名由開局設定。  
> 通告／製作方見下方 `comp_*`（CompanyDatabase），兩者不可混用。

| id | 顯示名（占位） | 狀態 | 備註 |
|----|----------------|------|------|
| `agency_player` | （玩家自訂） | in_game | `PlayerManager.get_company_name()` |
| `agency_001` | 索尼 | placeholder | NPC 經紀 |
| `agency_002` | 滚石 | placeholder | NPC 經紀 |
| `agency_003` | 卢卡斯 | placeholder | NPC 經紀 |
| `agency_004` | 迪士尼 | placeholder | NPC 經紀 |
| `agency_005` | 华纳 | placeholder | NPC 經紀 |

> 藝人 `home_agency_id` 指向以上 id；簽約後由系統視為 `agency_player`（藝人 id 不變）。  
> 程式：`scripts/autoload/AgencyDatabase.gd`

---

## 通告／製作公司（CompanyDatabase）

> **僅發布通告、出品作品，不可簽約藝人。** 與經紀公司永久分開。  
> 程式：`scripts/autoload/CompanyDatabase.gd`  
> 對話變數：`{publisher_name}`、`{job_company_name}`

| id 前綴 | 類型 | 範例 |
|---------|------|------|
| `comp_film_*` | 電影 | `comp_film_01` 穹宇映画 |
| `comp_tv_*` | 電視／綜藝 | `comp_tv_01` 草莓卫视 |
| `comp_music_*` | 音樂 | `comp_music_01` 灵动唱片 |
| `comp_ad_*` | 廣告 | `comp_ad_01` 蓝图视觉 |
| `comp_*_intl_*` | 國際 | `comp_film_intl_01` |

設施 `FacilityResource.linked_company_id` 指向 `comp_*`（類型 `COMPANY`）。

---

## 我方藝人（artist_001～016）

> **全部 16 人都算我方**（一滴血原則，id 不變）。能否加入 roster 由劇情 gate 決定，**不是**陣營分類。  
> 資源路徑：`data/artists/artist_NNN/`。`ArtistManager.all_artists` 載入。

| id | 顯示名 | home_agency | opening_pick | fixed_story_join | poachable_in | poachable_out | sibling | 初始好感 |
|----|--------|-------------|--------------|------------------|--------------|---------------|---------|----------|
| `artist_001` | Yuka | — | 是 | — | — | — | — | 20 |
| `artist_002` | Valeria | — | 是 | — | — | **是** | — | 25 |
| `artist_003` | 米语 | — | 是 | — | — | — | — | 15 |
| `artist_004` | 四号 | agency_001 | — | **是** | — | — | — | 10 |
| `artist_005` | 五号 | agency_002 | — | — | **是** | — | artist_006 | 10 |
| `artist_006` | 六号 | agency_002 | — | — | **是** | — | artist_005 | 10 |
| `artist_007` | 七号 | — | — | — | — | — | — | 10 |
| `artist_008` | 八号 | — | — | — | — | — | — | 10 |
| `artist_009` | 九号 | — | — | — | — | — | — | 10 |
| `artist_010` | 十号 | — | — | — | — | — | — | 10 |
| `artist_011` | 十一号 | — | — | — | — | — | — | 10 |
| `artist_012` | 十二号 | — | — | — | — | — | — | 10 |
| `artist_013` | 十三号 | — | — | — | — | — | — | 10 |
| `artist_014` | 十四号 | — | — | — | — | — | — | 10 |
| `artist_015` | 十五号 | — | — | — | — | — | — | 10 |
| `artist_016` | 十六号 | — | — | — | — | — | — | 10 |

> **004～016 僅 `artist_004` 走固定劇情加入**（`fixed_story_join`）。  
> **挖角兄妹**：`artist_005` ↔ `artist_006`（同挂 agency_002）。  
> **007～016**：我方占位，劇情觸發後可入 roster；簽約／挖角只改 `home_agency_id` 與 roster，**id 不變**。

### 人設創作欄

| id | 創作用顯示名 | 暱稱 / 外號 | 一句話 | 人設檔 |
|----|--------------|-------------|--------|--------|
| `artist_001` | Yuka | | 甜美吉他手 | `01_Characters/artist_001.md` |
| `artist_002` | Valeria | | 棕肤内向舞台剧 | `01_Characters/artist_002.md` |
| `artist_003` | 米语 | | 韩系御姐舞者 | `01_Characters/artist_003.md` |
| `artist_004`～`016` | | | | （待建） |

---

## 競爭對手（rival_001～）

> **永不可簽約**；掛 NPC 經紀，參與通告／頒獎等競爭。  
> 資源路徑：`data/rivals/rival_NNN/`。`RivalManager.all_rivals` 載入；复用 `ArtistResource`（`artist_id` 填 `rival_NNN`）。

| id | 顯示名 | home_agency | 初始好感 | 備註 |
|----|--------|-------------|----------|------|
| `rival_001` | 对手1号 | agency_003 | 10 | 能力值已配 |
| `rival_002` | 对手2号 | agency_003 | 10 | |
| `rival_003` | 对手3号 | agency_004 | 10 | |
| `rival_004` | 对手4号 | agency_004 | 10 | |
| `rival_005` | 对手5号 | agency_005 | 10 | |
| `rival_006` | 对手6号 | agency_005 | 10 | |
| `rival_007` | 对手7号 | agency_001 | 10 | |
| `rival_008` | 对手8号 | agency_002 | 10 | |
| `rival_009` | 对手9号 | agency_003 | 10 | |
| `rival_010` | 对手10号 | agency_004 | 10 | |

---

## NPC 分類

| 類型 | id 格式 | 資源 | 好感 | 管理器 | 說明 |
|------|---------|------|------|--------|------|
| **秘書** | `secretary` | `npc_secretary.tres` | 10 | `SecretaryManager` | 特殊 NPC，大量主線對白；**不**走 `npc_*` |
| **劇情 NPC** | `npc_{角色}_{NN}` | `data/npcs/.../npc_*.tres` | 10（預設） | `NpcManager` | 具名、頭像、常駐設施或劇情觸發 |
| **路人** | 無固定 id | 對話內嵌 | 無 | — | `NPCType.BACKGROUND`；不登記 RelationshipManager |

> **路人 NPC** 不需要建 `.tres`；劇本裡直接寫台詞即可。  
> 新增劇情 NPC：下一個 `npc_*` 序號 + `data/npcs/{npc_id}/`（資料夾名 = 邏輯 id）+ 在設施 `available_npcs` 掛載（若常駐）。

---

## NPC 登記表

| id | 顯示名 | type | 可好感 | 初始好感 | home_facility | 狀態 | godot 資源 |
|----|--------|------|--------|----------|---------------|------|------------|
| `secretary` | 小唯 | STORY | 是 | 10 | — | in_game | `data/npcs/secretary/npc_secretary.tres` |
| `npc_shopkeeper_01` | 商店老板 | STORY | 是 | 10 | `fac_shop` | in_game | `data/npcs/npc_shopkeeper_01/npc_shopkeeper_01.tres` |

### NPC 創作欄（待建）

| id | 創作用顯示名 | 登場設施 / 章節 | 人設檔 |
|----|--------------|-----------------|--------|
| `npc_shopkeeper_01` | | 便利商店 `fac_shop` | |
| （待建） | | 酒吧 `fac_bar` | |
| （待建） | | 醫院 `fac_hospital` | |
| （待建） | | 美術館 `fac_art_gallery` | |

> 新增 NPC：`npc_{描述}_{NN}`。秘書**不要**另建 `npc_secretary_01`。

---

## 養成修正（僅我方 16 藝人，在 `.tres` 手動填）

欄位定義見 `Artist_Resource.gd` 的「養成修正」分組：

| 欄位 | 說明 |
|------|------|
| `contract_diff_mod` | 簽約難度修正%（疊加基準 50） |
| `fail_rate_abs` | 失敗率絕對值修正%（百分點） |
| `perfect_rate_abs` | 完美率絕對值修正%（百分點） |
| `morality_mod` | 道德變化倍率修正%（100+mod 為倍率） |
| `favor_gain_mod` | 好感提升倍率修正%（100+mod 為倍率） |
| `stress_gain_mod` | 壓力獲得倍率修正%（2026-06-19 新增） |
| `fatigue_gain_mod` | 疲勞獲得倍率修正%（2026-06-19 新增） |
| `satisfaction_gain_mod` | 滿意度獲得倍率修正%（2026-06-19 新增） |

> 001～003 已從舊性格矩陣遷移初值；004～016 預設 0，由企劃在編輯器逐人調整。人設 md 8 欄寫在折疊 callout。

---

## 事件 ID 登記（劇本匯入用 · 2026-06-20 同步 vault）

| event_id | 標題 | character_id | trigger | 狀態 | 寫作檔 |
|----------|------|--------------|---------|------|--------|
| `story_sign_artist_001_street_01` | Yuka 路邊簽約 | artist_001 | sign | draft | `1_Main_Story/Artists/artist_001/00_street_sign_01.md` |
| `story_meeting_artist_001_first_session_01` | Yuka 首次周會 | artist_001 | meeting / first | draft | `.../01_first_meeting_01.md` |
| `story_sign_artist_002_theater_01` | Valeria 劇院簽約 | artist_002 | sign | draft | `Artists/artist_002/00_theater_sign_01.md` |
| `story_meeting_artist_002_first_session_01` | Valeria 首次周會 | artist_002 | meeting / first | draft | `.../01_first_meeting_01.md` |
| `story_sign_artist_003_day1_office_01` | 米语 office 簽約 | artist_003 | sign | draft | `Artists/artist_003/00_office_sign_01.md` |
| `story_meeting_artist_003_first_session_01` | 米语 首次周會 | artist_003 | meeting / first | draft | `.../01_first_meeting_01.md` |
| `story_visit_npc_shopkeeper_01_intro_01` | 商店首次進店 | npc_shopkeeper_01 | visit | draft | `Npcs/npc_shopkeeper_01/00_intro_first_visit_01.md` |
| `story_meeting_first_session_01` | 首次週日會議（秘書·舊共用 id） | secretary | meeting / first | in_game | `scripts/story_meeting_first_session_01.md` |
| `story_meeting_weekly_flavor_01` | 常规周会秘书 flavor | secretary | meeting / weekly | in_game | `scripts/story_meeting_weekly_flavor_01.md` |
| `story_follow_gig_bar_01` | 酒吧駐唱後台 | — | follow / `gig:gig_bar_singer_01` | in_game | |
| `story_follow_gig_bar_parallel` | （並列測試） | — | follow | in_game | |
| `story_visit_bar_gig_01` | 探望·酒吧 | — | visit / `gig:gig_bar_singer_01` | in_game | |
| `story_visit_tv_variety_01` | 探望·綜藝 | — | visit / `job:test_job_tv_variety_01` | in_game | |

> **Godot 占位仍用舊 event_id**（`story_sign_artist_00X_first_meeting` 等）；生成新 `.tres` 時改用上表 id。日常池（Meeting_Weekly / Schedule_Result / Map 等）見 `02_Story_Events/2_Daily_Loops/` 各 md frontmatter。

---

## 通告／打工 ID（非角色，劇本引用用）

| 類型 | id 格式 | 管理器 | 資料目錄 | 現有 |
|------|---------|--------|----------|------|
| 通告 | `job` 模板 id | `JobManager` | `data/jobs/` | 4 則測試模板 |
| 打工 | `gig_*` | `GigManager` | `data/gigs/` | `gig_bar_singer_01` |
| 課程 | `course_*` | `CourseManager` | `data/courses/` | `course_acting_basic_01`（開局解鎖） |
| 度假 | `vacation_*` | `VacationManager` | `data/vacations/` | `vacation_domestic_spring_01` |

跟隨／探望簽名：`gig:{gig_id}`、`job:{job_id}`（見上方事件表）。

---

## 沙盒驗證（2026-06-18）

```bash
python3 tools/run_all_sandboxes.py
```

| 沙盒 | 驗證內容 | 結果 |
|------|----------|------|
| `character_database_sandbox.py` | 16 藝人 + 10 rival + 劇情 gate | ✅ |
| `artist_profile_sandbox.py` | 藝人檔案、16 份 `.tres` | ✅ |
| `agency_database_sandbox.py` | 6 經紀 + `comp_*` API | ✅ |
| `npc_database_sandbox.py` | NpcManager + 設施 NPC | ✅ |
| `job_facility_alignment_sandbox.py` | 通告／課程／設施／公司三角對齊 | ✅ |
| `follow_story_sandbox.py` | 跟隨／探望簽名 | ✅ |
| `save_v1_sandbox.py` | 通告存檔 | ✅ |

其餘行程／日循環／UI 沙盒見 [`README.md`](README.md)。

---

## 變更紀錄

| 日期 | 變更 |
|------|------|
| 2026-06-20 | vault 全量同步 MyIdolGameScript-main（6.19）；event 登記更新；8 欄養成修正 |
| 2026-06-18 | 初版：對齊 artist_001~003、secretary、protagonist、npc_shopkeeper_01 |
| 2026-06-18 | CharacterDatabase；秘書 npc_id=secretary；5 間 agency |
| 2026-06-18 | artist_004～016 建檔；004 固定劇情加入；005/006 挖角兄妹 |
| 2026-06-18 | **陣營重構**：artist_001～016 全為我方；競爭對手改 rival_NNN + RivalManager |
| 2026-06-18 | **NPC 中樞**：NpcManager + npc_* 劇情 NPC；秘書仍走 SecretaryManager |
| 2026-06-18 | MyIdolGameScript 匯入對齊：artist_001=Yuka、002=Valeria、003=米语；劇本 frontmatter + 目錄重組 |
| 2026-06-18 | 通告拍攝地與 `comp_*` 對齊；課程開局解鎖；`fac_airport_intl` 命名統一 |
