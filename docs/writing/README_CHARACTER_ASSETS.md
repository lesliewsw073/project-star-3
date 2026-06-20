# 角色視覺資源規格（頭像／立繪／CG）

> 遊戲視窗：**1600×900**（`project.godot`）  
> 程式路徑：`CharacterVisualPaths.gd`  
> `.tres` 的 `avatar`／`portrait` 可留空；放入標準檔名後會**自動從資料夾載入**。

---

## 目錄結構（每人一夾，三種圖）

```
assets/characters/
  artists/artist_NNN/
    avatar/artist_NNN_avatar.png      ← 小頭像
    portrait/artist_NNN_portrait.png  ← 半身透明立繪
    cg/
      artist_NNN_cg_{場景key}.png     ← 劇情 CG（可多張）
  rivals/rival_NNN/                   ← 同上
  npcs/secretary/                     ← 同上（小唯）
  npcs/npc_shopkeeper_01/              ← 同上（店長，id 與資料夾一致）
```

**請勿再放**舊路徑 `portraits/`、`imported/`。

---

## 三種圖的用途

| 類型 | 用途 | Demo 顯示處 |
|------|------|-------------|
| **avatar** | 列表、存檔槽、排程表小圖 | 44～112 px 方塊 |
| **portrait** | 對話半身立繪、簽約、會議大圖 | 對話左側約 420×700 |
| **cg** | 劇情插畫，類似**全螢幕背景**；對話框照常進行 | 1600×900 鋪滿後方 |

CG 觸發時：底層顯示 CG → 上層半透明遮罩 → 底部對話框 + 半身立繪，**台詞照常打字／點擊繼續**。

---

## 檔案規格（請依此重新出圖）

### 1. 頭像 `avatar`

| 項目 | 建議 |
|------|------|
| 畫布 | **512×512 px**（正方形） |
| 格式 | PNG，透明底或裁切到肩部以上 |
| 內容 | 臉部特寫，占畫面約 70～80% |
| 檔名 | `{id}_avatar.png`，例 `artist_003_avatar.png` |
| 大小 | 單檔建議 **≤ 500 KB**（512 足夠清晰，勿用幾 MB 當小圖） |

### 2. 半身立繪 `portrait`

| 項目 | 建議 |
|------|------|
| 畫布 | **900×1400 px**（約 9:14，可略調） |
| 格式 | **PNG RGBA，透明背景** |
| 內容 | 半身～腰上，角色置中略偏下，留頭頂空間 |
| 檔名 | `{id}_portrait.png` |
| 大小 | 單檔建議 **1～3 MB**（線條清晰即可，不必過度超大） |

> 舊的 256×256 僅適合占位；Demo 請用 **900×1400** 源圖，由 Godot 縮放。

### 3. 劇情 CG `cg`

| 項目 | 建議 |
|------|------|
| 畫布 | **1600×900 px**（16:9，與遊戲視窗一致） |
| 格式 | PNG 或 JPG；可不透明（場景圖） |
| 內容 | 橫幅構圖，重要角色／場景；對話時當背景 |
| 檔名 | `{id}_cg_{場景key}.png` |
| 範例 | `artist_003_cg_sign_01.png`、`artist_003_cg_meeting_cake.png` |
| 大小 | JPG 建議 **≤ 1.5 MB**；PNG 可至 3 MB |

---

## 劇本裡的 `cg_id`

`InteractionEventResource.cg_id` 填**場景 key**（不含路徑）：

| cg_id（事件欄位） | 對應檔案（owner=`artist_003`） |
|------------------|-------------------------------|
| `sign_01` | `artist_003/cg/artist_003_cg_sign_01.png` |
| `meeting_cake` | `artist_003/cg/artist_003_cg_meeting_cake.png` |

也可用完整 stem：`artist_003_cg_sign_01`（程式會自動對應檔名）。

`owner` 或 `character_id` 決定角色資料夾；CG 與對話**同時顯示**，不會擋住對話操作。

---

## 匯入步驟（勇者大人重新供圖後）

1. 將三類檔案放入上表對應資料夾（檔名必須一致）。
2. 打開 Godot，讓編輯器自動 import（無需改 `.tres` 也可運行）。
3. 可選：在 `artist_NNN.tres` 手動指定 `avatar`／`portrait` 覆寫自動載入。
4. 劇情 `.tres` 的 `cg_id` 填場景 key，測試對話 + CG 疊層。

---

## 目前已清空

專案內舊角色 PNG 已全部刪除（保留 `icon.svg`）。  
空資料夾已建好（artist_001～016、rival_001～010、secretary、npc_shopkeeper_01），可直接投放新圖。
