class_name ItemResource
extends Resource

## 道具靜態資料（四大類：公司／屬性／劇情／藝人贈禮）。
## 物品欄（背包）僅存放 ATTRIBUTE、STORY。

enum ItemCategory {
	COMPANY,
	ATTRIBUTE,
	STORY,
	ARTIST_GIFT,
}

enum HomeDisplaySlot {
	NONE,
	CABINET,
	BEDSIDE,
	SHELF,
}

const STAT_MAX: int = 999
const METER_MAX: int = 100

@export_group("基礎")
@export var item_id: String = ""
@export var item_name: String = "未命名道具"
@export_enum("公司物品", "屬性道具", "劇情道具", "藝人贈禮") var item_category: int = ItemCategory.ATTRIBUTE
@export_multiline var description: String = ""
@export var shop_price: int = 0 ## 0 = 不可商店購買

@export_group("內容分級")
@export var is_test_content: bool = false

@export_group("公司物品（不進物品欄）")
@export_range(0, 9999) var reputation_bonus: int = 0 ## 持有時計入公司聲望加成上限
@export_range(0, 9999) var public_opinion_bonus: int = 0 ## 持有時計入口碑加成上限
@export var meeting_display_key: String = "" ## 會議室地圖展示用 key

@export_group("屬性道具（可贈我方藝人）")
@export_range(-100, 100) var add_fatigue: int = 0
@export_range(-100, 100) var add_stress: int = 0
@export_range(-100, 100) var add_satisfaction: int = 0
@export_range(-100, 100) var add_affection: int = 0
@export_range(-999, 999) var add_empathy: int = 0
@export_range(-999, 999) var add_timbre: int = 0
@export_range(-999, 999) var add_improvisation: int = 0
@export_range(-999, 999) var add_acting: int = 0
@export_range(-999, 999) var add_singing: int = 0
@export_range(-999, 999) var add_eloquence: int = 0
@export_range(-999, 999) var add_dynamism: int = 0
@export_range(-999, 999) var add_talent: int = 0
@export_range(-999, 999) var add_stamina: int = 0
@export_range(-999, 999) var add_deportment: int = 0
@export_range(-999, 999) var add_fashion: int = 0
@export_range(-999, 999) var add_confidence: int = 0
@export_range(-999, 999) var add_rebelliousness: int = 0
@export_range(-999, 999) var add_humor: int = 0
@export_range(-999, 999) var add_affinity: int = 0
@export_range(-999, 999) var add_fame: int = 0
@export_range(-999, 999) var add_popularity: int = 0
@export_range(-999, 999) var add_exposure: int = 0
@export_range(-999, 999) var add_morality: int = 0

@export_group("劇情道具")
@export var story_use_event_id: String = "" ## 劇情／事件中使用
@export var gift_story_event_id: String = "" ## 贈送後觸發（不改能力值）

@export_group("藝人贈禮（玩家家中展示）")
@export var default_source_artist_id: String = ""
@export_enum("無", "櫃子", "床頭", "書架") var home_display_slot: int = HomeDisplaySlot.NONE

func is_bag_item() -> bool:
	return item_category == ItemCategory.ATTRIBUTE or item_category == ItemCategory.STORY

func can_gift_to_signed_artist() -> bool:
	return item_category == ItemCategory.ATTRIBUTE or item_category == ItemCategory.STORY

func validate_config() -> String:
	if item_id.strip_edges() == "":
		return "缺少 item_id。"
	match item_category:
		ItemCategory.COMPANY:
			if reputation_bonus <= 0 and public_opinion_bonus <= 0:
				return "%s：公司物品應至少提供聲望或口碑加成。" % item_id
		ItemCategory.ARTIST_GIFT:
			if int(home_display_slot) == HomeDisplaySlot.NONE:
				return "%s：藝人贈禮需指定 home_display_slot。" % item_id
	return ""
