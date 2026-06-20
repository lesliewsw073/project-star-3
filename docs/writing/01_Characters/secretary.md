---
id: secretary
type: secretary
display_name: 小唯
gender: female
status: in_game
godot_resource: res://data/npcs/secretary/npc_secretary.tres
initial_affection: 10
---

## 一句話

冷淡毒舌的公司秘書，邏輯 id 固定 `secretary`，遊戲內顯示名 **小唯**。

## 核心設定

- **職能**：週報、週日會議引導、公司營運提醒。
- **好感規則（硬性）**：**不可收禮**；僅能透過談話、獲獎、公司規模、特定劇情提升。
- **程式**：`SecretaryManager` 專管；**不**使用 `npc_*` 前綴 id。

## id 約定

| 欄位 | 值 |
|------|-----|
| 邏輯 id | `secretary`（不可改） |
| 顯示名 | **小唯** |
| 舊稿代號 | `S_Yui`（僅匯入對照，勿寫進劇本 speaker_id） |

## 對話變數

- `{secretary_name}` → 運行時 `SecretaryManager.get_display_name()`（小唯）
