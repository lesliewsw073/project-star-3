# 道具／貨幣／物品欄規範

> 程式入口：`ItemManager` + `ItemDatabase` + `InventoryManager`（物品欄）  
> 資料目錄：`data/items/`

---

## 貨幣（三種）

| 貨幣 | 欄位 | 用途 | v1 狀態 |
|------|------|------|---------|
| **金幣** | `PlayerManager.money` | 簽約、購物、月薪、演唱會、升級大樓、自費企劃等 | ✅ 已接 |
| **聲望** | `PlayerManager.company_reputation` | 公司規模、正向經營累積 | ✅ 已有；細則待埋 |
| **口碑** | `PlayerManager.company_public_opinion` | 簽約難度、頒獎資格等；**不參與公司規模升級** | ✅ 欄位已加；增減待埋 |

### 金幣（虛構）

- 顯示單位：**金幣**（`$` 前綴僅 UI 占位，非真實貨幣）
- **月薪**：每月第一個週日會議（`TimeManager.is_month_start()`）由 `ItemManager.try_process_monthly_salary()` 扣除（v1 占位：每位簽約藝人 5000）

### 口碑（待埋坑）

- 通告完成率、開天窗、自創劇本逾期、負面新聞等 → `reduce_public_opinion`
- 具體數值與閾值後續在 `JobManager` / `NewsManager` 等處掛鉤

---

## 道具四大類

| 類別 | enum | 進物品欄 | 說明 |
|------|------|----------|------|
| 公司物品 | `COMPANY` | ❌ | 購買後展示於會議室；聲望／口碑按最高檔**邊際增量** |
| 屬性道具 | `ATTRIBUTE` | ✅ | 可贈**已簽約藝人**；屬性滿則該項不加 |
| 劇情道具 | `STORY` | ✅ | 事件中使用或贈送觸發劇情；不改能力值 |
| 藝人贈禮 | `ARTIST_GIFT` | ❌ | 藝人送出 → 玩家家中展示（櫃子／床頭／書架） |

---

## item_id 命名

```text
comp_item_{場景}_{名稱}_{序號}    # 公司
attr_item_{類型}_{序號}            # 屬性
story_item_{名稱}_{序號}           # 劇情
gift_{artist_id}_{名稱}_{序號}     # 藝人贈禮
```

---

## 公司物品：聲望／口碑邊際規則

持有多件時，**有效加成 = 各件 bonus 的最大值**；購買新件時只結算 `new_max - old_applied`。

示例：

- 先買 `comp_item_meeting_plant_01`（+50 聲望）→ 聲望 +50
- 再買 `comp_item_meeting_sofa_02`（+100 聲望、+20 口碑）→ 聲望再 +50、口碑 +20
- 兩件都保留在 `_owned_ids`，會議室地圖讀 `meeting_display_key`

---

## 物品欄（InventoryManager）

- 只存 `ATTRIBUTE`、`STORY`
- `get_bag_entries()`：count > 0 才顯示
- 存檔 key：`inventory`（Save v1 相容）

---

## 秘書（secretary）

- 顯示名：**小唯**（邏輯 id 固定 `secretary`）
- **不可收禮**；好感僅：談話、獲獎、公司規模、特定劇情。
- 週會送禮／`try_gift_to_artist` 僅限已簽約 `artist_*`。

## 商店購買

- 入口：大地圖 `fac_shop`（`FacilityType.SHOP`）→「購買道具」
- API：`ItemManager.try_purchase(item_id)`；目錄：`ItemManager.get_shop_catalog()`
- `shop_price > 0` 且非 `ARTIST_GIFT` 方可購買；公司物品已持有不可重複購買

## 程式 API 速查

```gdscript
# 購買（公司／屬性／劇情）
ItemManager.try_purchase("attr_item_energy_drink_01")

# 贈送屬性／劇情道具給已簽約藝人
ItemManager.try_gift_to_artist("attr_item_perfume_01", "artist_001")

# 劇情道具在事件中消耗
ItemManager.try_use_story_item("story_item_old_letter_01", {"context": "..."})

# 藝人贈禮進家
PlayerHomeManager.try_receive_artist_gift("gift_artist_001_handmade_01", "artist_001")

# 會議室展示
CompanyItemManager.get_meeting_display_keys()
```

---

## 占位資料（已入庫）

| item_id | 類別 |
|---------|------|
| `comp_item_meeting_plant_01` | 公司 +50 聲望 |
| `comp_item_meeting_sofa_02` | 公司 +100 聲望、+20 口碑 |
| `attr_item_energy_drink_01` | 屬性 -15 疲勞 |
| `attr_item_perfume_01` | 屬性 +口才/+好感 |
| `story_item_old_letter_01` | 劇情占位 |
| `gift_artist_001_handmade_01` | 001 手作書籤 → 櫃子 |

---

## 存檔欄位

```json
{
  "player": { "company_public_opinion": 0 },
  "inventory": { "attr_item_energy_drink_01": 2 },
  "company_items": {
    "owned_ids": ["comp_item_meeting_plant_01"],
    "applied_reputation_bonus": 50,
    "applied_public_opinion_bonus": 0
  },
  "player_home": {
    "gifts": [{ "item_id": "...", "artist_id": "...", "home_display_slot": 1 }],
    "artist_gift_counts": { "artist_001": 1 }
  }
}
```
