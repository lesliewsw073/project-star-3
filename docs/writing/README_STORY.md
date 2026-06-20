# 劇本／事件寫作規範（Obsidian ↔ Godot）

> 對齊程式：`InteractionEventResource` + `data/story_events/`  
> 角色 id 主表：[`CHARACTER_REGISTRY.md`](CHARACTER_REGISTRY.md)  
> **2026-06-19 定案詳細版**：[`00_Project_Spec/剧本event正文格式标准.md`](00_Project_Spec/剧本event正文格式标准.md)

---

## Obsidian 資料夾 ↔ Godot 路徑（2026-06-19）

| Obsidian（`02_Story_Events/`） | Godot（目標結構，尚未全量同步） |
|--------------------------------|--------------------------------|
| `1_Main_Story/Artists/artist_NNN/` | `data/story_events/main/artists/artist_NNN/` |
| `1_Main_Story/Npcs/npc_*` | `data/story_events/main/npcs/npc_*/` |
| `2_Daily_Loops/Artists/Meeting_Weekly/` | `data/story_events/daily/artists/.../meeting/` |
| `2_Daily_Loops/Artists/Schedule_Result/` | `data/story_events/daily/artists/.../schedule_result/` |
| `2_Daily_Loops/Artists/Visit_Flavor/` | `data/story_events/daily/artists/.../visit/` |
| `2_Daily_Loops/Artists/Map_Encounters/` | `data/story_events/daily/artists/.../map/` |
| `2_Daily_Loops/Npcs/npc_*` | `data/story_events/daily/npcs/npc_*/` |
| `3_Cross_Interactions/Duo/` | `data/story_events/cross/duo/` |
| `5_Secretary/` | `data/story_events/meeting/` 或 `secretary/` |

**第一層必須分 `Artists` / `Npcs`。** 無 `Follow_Flavor/`（`follow` 僅觸發綁定 event）。  
**探班** `visit` = 通告拍攝期在拍攝地點；**偶遇** `map` = 自由日大地圖。

**規則：** Obsidian 寫 markdown + frontmatter；匯入 Godot 時生成或手動維護同名 `.tres`。  
**主鍵永遠是 `event_id`**，不是檔名。

---

## `event_id` 命名規範（必須遵守）

格式：

```text
story_{通道}_{主體或場景}_{序號}
```

| 通道 key | story_channel | 示例 |
|----------|---------------|------|
| `sign` | SIGN | `story_sign_artist_001_street_01` |
| `meeting` | MEETING | `story_meeting_artist_001_first_session_01` |
| `schedule_result` | SCHEDULE_RESULT | `story_schedule_result_artist_001_success_01` |
| `follow` | FOLLOW | `story_follow_gig_bar_01` |
| `visit` | VISIT | `story_visit_bar_gig_01` |
| `map` | MAP | `story_map_fac_bar_flavor_01` |
| `calendar` | CALENDAR | `story_calendar_artist_004_w03_01` |

**硬性規則：**

1. 全小寫、底線分隔；**全局唯一**。
2. 角色 id 用程式 id：`artist_001`，不用「一号」或 `001` 省略前缀。
3. `follow` 与 `visit` **不得共用** 同一 `event_id`。
4. duo 事件：`story_duo_artist_004_005_main_01`，`owner: duo:artist_004+artist_005`。
5. 群像：`story_ensemble_company_party_01`，`owner: ensemble:company_party_01`。

---

## Obsidian frontmatter 模板

```yaml
---
event_id: story_meeting_first_session_01
event_title: 首次週日會議
arc_type: secretary_tutorial   # 见下表
owner: secretary
story_channel: meeting
meeting_scope: first           # 会议专用：first / weekly / 留空
participants: [secretary]
character_id: secretary        # 好感结算对象（可空）
execute_once: true
blocking: true                # 阻塞式播放，不代表跨日剧情占用
affection_settlement: once     # none | once | per_line
affection_delta: 2             # 或用 affection_targets
priority: 200
cooldown_days: 0
pool_id: ""
required_flags: {}
sets_flags:
  meeting.first_session_done: true
godot_resource: res://data/story_events/meeting/00_first_session.tres
---
```

### `arc_type` 枚举（frontmatter 用小写 snake）

| 值 | 说明 |
|----|------|
| `generic` | 通用 |
| `main_once` | 个人主线一次性 |
| `first_meeting` | 签约后首次相遇（SIGN 通道） |
| `flavor_repeat` | 日常重复 |
| `duo_once` | 双人一次性 |
| `ensemble_once` | 群像 |
| `leave_once` | 解约离开 |
| `message` | 简讯 |
| `secretary_tutorial` | 秘书教学 |
| `secretary_flavor` | 秘书日常 |

### `story_channel` 枚举

`any` | `sign` | `calendar` | `meeting` | `follow` | `visit` | `map` | `hospital` | `award` | `phone` | `ending` | `manual`

### `meeting_scope`（仅 MEETING 通道）

| 值 | 何时匹配 |
|----|----------|
| `first` | 仅 `GamePhase.FIRST_MEETING` 首次周日会议 |
| `weekly` | 非首次的常规周日会议 |
| （空） | 两种会议都可（靠 priority / flag 控制） |

---

## 对话正文格式（Obsidian 正文区）

```markdown
| speaker_id | speaker_name | text |
|------------|--------------|------|
| secretary | 小唯 | 製作人，歡迎來到首次週日會議。 |
| protagonist | | 明白了。 |
```

- `speaker_id` 必须用 `CHARACTER_REGISTRY` 中的 id。
- `speaker_name` 可留空，运行时由 `CharacterDatabase` 解析。
- 变量：`{player_address}`、`{company_name}` 等见 `DialogueVariableResolver`。

---

## 结算铁律（防重复）

1. 一个 `event_id` 只结算一次（除非 `affection_settlement: per_line`）。
2. duo / ensemble 剧本只存一份，个人文件夹只放 wikilink。
3. 有 `dialogue` 时：先播对话，播完再结算（`StoryPlaybackController`）。

---

## 当前已入库示例（Godot · 待同步 6.19 vault）

| event_id | 通道 | 说明 |
|----------|------|------|
| `story_sign_artist_001_first_meeting` 等 | sign | **旧 id**，Godot 占位仍用；写作侧已改见下 |
| `story_meeting_first_session_01` | meeting | 首次周日会议秘书开场（旧共用 id） |
| `story_meeting_weekly_flavor_01` | meeting | 常规周会秘书 flavor |
| `story_follow_gig_bar_01` | follow | 酒吧驻唱跟随 |
| `story_visit_bar_gig_01` | visit | 探望酒吧 |

### 写作侧已定稿（2026-06-19 · 待生成 .tres）

| event_id | 写作档 |
|----------|--------|
| `story_sign_artist_001_street_01` | `1_Main_Story/Artists/artist_001/00_street_sign_01.md` |
| `story_meeting_artist_001_first_session_01` | `.../01_first_meeting_01.md` |
| `story_sign_artist_002_theater_01` | `Artists/artist_002/00_theater_sign_01.md` |
| `story_sign_artist_003_day1_office_01` | `Artists/artist_003/00_office_sign_01.md` |
| `story_visit_npc_shopkeeper_01_intro_01` | `Npcs/npc_shopkeeper_01/00_intro_first_visit_01.md` |

---

## flag 命名建议

```text
first_meeting.{artist_id}_done
meeting.first_session_done
main.{artist_id}.{序号}_done
duo.{id_a}_{id_b}.{序号}_done
story.cooldown.{event_id}          # 程序自动写，勿手填
```
