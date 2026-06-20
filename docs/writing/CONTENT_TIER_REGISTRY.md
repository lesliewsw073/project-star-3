# 內容分級登記表（測試 vs 正式）

> **唯一真相**：除下方「正式稿」外，目前預填內容皆視為 **測試／占位**。  
> 資源欄位：`is_test_content`（見各 `*Resource.gd`）。  
> 規範：`.cursor/rules/test-content-marking.mdc`

最後同步：2026-06-20

---

## 正式稿（`is_test_content = false`）

| 類型 | 路徑／id | 備註 |
|------|----------|------|
| 我方藝人 | `artist_003` / `data/artists/artist_003/` | 米语；人設檔已產出 |
| 主線劇本 | `data/story_events/main/artist_003/*.tres` | 簽約 → 首日 → 首次週會 |
| 人設文稿 | `docs/writing/01_Characters/artist_003.md` | 勇者大人親筆 |
| 秘書 | `secretary` / `data/npcs/secretary/` | 小唯；邏輯角色，非測試 |

---

## 測試稿（`is_test_content = true`）

### 通告 `data/jobs/test/`

| job_id | 顯示名 | 備註 |
|--------|--------|------|
| `test_job_ad_shoot_01` | 晨光飲品廣告 | |
| `test_job_movie_short_01` | 穹宇映畫短片 | `invite_only` 邀請接案測試 |
| `test_job_music_solo_01` | 星潮單曲錄製 | |
| `test_job_tv_variety_01` | 草莓衛視週末綜藝 | |

### 打工／課程／度假

| id | 顯示名 |
|----|--------|
| `gig_bar_singer_01` | 酒吧駐唱 |
| `course_acting_basic_01` | 影視表演基礎班 |
| `vacation_domestic_spring_01` | 近郊溫泉療癒 |

### 道具 `data/items/`（6 則占位）

| item_id | 顯示名 |
|---------|--------|
| `comp_item_meeting_plant_01` | 會議室綠植 |
| `comp_item_meeting_sofa_02` | 會議室真皮沙發 |
| `attr_item_energy_drink_01` | 能量飲料 |
| `attr_item_perfume_01` | 精品香水 |
| `story_item_old_letter_01` | 舊日信件 |
| `gift_artist_001_handmade_01` | 手作小書籤 |

### 劇情事件（占位）

| event_id | 顯示名 | 備註 |
|----------|--------|------|
| `story_sign_artist_001_first_meeting` | 首次相遇 | 001 占位 |
| `story_sign_artist_002_first_meeting` | 首次相遇 | 002 占位 |
| `story_meeting_first_session_01` | 首次週日會議 | 通用占位 |
| `story_meeting_weekly_flavor_01` | 週會開場 | 重複池占位 |
| `story_follow_gig_bar_01` | 酒吧駐唱後台 | |
| `story_follow_gig_bar_parallel` | 雙人同台後台 | |
| `story_visit_bar_gig_01` | 酒吧探望 | |
| `story_visit_tv_variety_01` | 綜藝錄製探望 | |

程式內測試事件：`test_chat_*`、`test_story_once_*`、`test_expensive_gift_*`（保留為開發鉤子，不掛到正常玩家流程）

### 藝人／對手

| 範圍 | 狀態 |
|------|------|
| `artist_001`～`002`、`004`～`016` | 占位數值／顯示名 |
| `rival_001`～`010` | 占位 |
| `npc_shopkeeper_01` | 占位 |
| `reporter_01` / `reporter_02` | 記者占位；新聞系統用 |

### 新聞模板 `data/news/templates/`

| template_id | 顯示名 |
|-------------|--------|
| `test_filler_weather_01` | 今日天氣 |
| `test_filler_vacation_01` | 度假推薦 |
| `test_filler_course_01` | 進修課程快訊 |

### 地圖／設施／公司表

| 範圍 | 狀態 |
|------|------|
| `data/locations/`、`data/facilities/` | 結構測試；文案占位 |
| `AgencyDatabase` / `CompanyDatabase` 內建名 | 占位公司名 |

### 公式占位

| 項目 | 位置 |
|------|------|
| 邀請接案分數權重 | `JobDayEvaluator.gd` |
| 月薪 5000／人 | `ItemManager.gd` |
| 公司物品邊際聲望 | `ItemManager` / README_ITEMS |

---

## 替換為正式稿時

1. `is_test_content = false`
2. 確認玩家可見名稱符合正式文案
3. 更新本表與 `CHARACTER_REGISTRY.md`（若涉及角色）
