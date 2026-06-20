class_name InteractionEventResource
extends Resource

## 互動／劇情事件資料（統一 schema：匹配 + 對話 + 結算）。
## 執行入口：StoryPlaybackController（有對話）或 InteractionManager（純效果）。

enum InteractionType { CHAT, GIFT, STORY_CHOICE, MEETING, SYSTEM }

## 舊版觸發場景；新事件請填 story_channel，載入時會互相同步。
enum TriggerContext { ANY, FOLLOW, VISIT, MEETING, MANUAL }

enum TriggerMode { SOLO, PARALLEL }

## 企劃 arc_type（對齊 Obsidian frontmatter）。
enum StoryArcType {
	GENERIC,
	MAIN_ONCE,
	FIRST_MEETING,
	FLAVOR_REPEAT,
	DUO_ONCE,
	ENSEMBLE_ONCE,
	LEAVE_ONCE,
	MESSAGE,
	SECRETARY_TUTORIAL,
	SECRETARY_FLAVOR,
}

## 觸發通道（follow ⊥ visit，不可混在同一 event）。
enum StoryChannel {
	ANY,
	SIGN,
	CALENDAR,
	MEETING,
	FOLLOW,
	VISIT,
	MAP,
	HOSPITAL,
	AWARD,
	PHONE,
	ENDING,
	MANUAL,
}

enum AffectionSettlement { NONE, ONCE, PER_LINE }

@export_group("基礎資訊")
@export var event_id: String = ""
@export var event_title: String = ""
@export_enum("聊天", "送禮", "劇情選項", "週日會議", "系統事件") var interaction_type: int = InteractionType.CHAT
@export var character_id: String = "" ## 結算主對象；duo 事件請用 affection_targets。
@export var related_company_id: String = ""
@export var related_job_id: String = ""
@export var execute_once: bool = false

@export_group("內容分級")
@export var is_test_content: bool = false

@export_group("劇本元數據")
@export_enum(
	"通用",
	"個人主線一次性",
	"首次相遇",
	"日常重複",
	"雙人一次性",
	"群像一次性",
	"解約離開",
	"簡訊",
	"秘書教學",
	"秘書日常"
) var arc_type: int = StoryArcType.GENERIC
@export var owner: String = "" ## artist_004 / duo:artist_004+artist_005 / ensemble:* / protagonist / secretary
@export var participants: PackedStringArray = PackedStringArray()
@export_enum(
	"任意",
	"簽約",
	"日期",
	"會議",
	"跟隨",
	"探望",
	"地圖偶遇",
	"住院",
	"頒獎",
	"手機",
	"結局",
	"手動"
) var story_channel: int = StoryChannel.MANUAL
@export var dialogue: DialogueSequence ## 有內容時由 StoryPlaybackController 播放後再結算
@export var blocking: bool = false ## true 時視為阻塞式劇情；不代表跨日劇情占用
@export var cg_id: String = ""
@export var meeting_scope: String = "" ## 會議專用：first / weekly；空=不限

@export_group("重複池")
@export var cooldown_days: int = 0 ## 0 = 僅靠 execute_once；>0 時在冷卻天數內不可再觸發
@export var pool_id: String = ""
@export var pool_weight: int = 1

@export_group("顯示文字")
@export_multiline var description: String = ""
@export_multiline var result_text: String = ""

@export_group("關係變化")
@export_range(-100, 100) var affection_delta: int = 0 ## 兼容舊欄；有 affection_targets 時以 targets 為準
@export_enum("無", "整段一次", "逐句") var affection_settlement: int = AffectionSettlement.ONCE
@export var affection_targets: Dictionary = {} ## character_id -> delta

@export_group("公司資源變化")
@export var money_delta: int = 0
@export var reputation_delta: int = 0
@export var public_opinion_delta: int = 0

@export_group("劇情旗標")
@export var flag_changes: Dictionary = {}

@export_group("觸發條件（legacy + 通道）")
@export_enum("任意", "跟隨", "探望", "會議", "手動") var trigger_context: int = TriggerContext.MANUAL
@export_enum("逐人觸發", "並列觸發") var trigger_mode: int = TriggerMode.SOLO
@export var location_id: String = ""
@export var facility_id: String = ""
@export var task_signature: String = ""
@export_range(0.0, 1.0) var trigger_chance: float = 1.0
@export var required_flags: Dictionary = {}
@export var priority: int = 0

@export_group("新聞")
@export var generate_news: bool = false
@export var news_title: String = ""
@export_multiline var news_body: String = ""
@export_enum("紙媒", "流媒體", "文字媒體") var news_media_type: int = 2
@export_enum("公司", "藝人", "通告", "選秀", "獎項", "作品發布", "醜聞", "業界") var news_category: int = 7
@export_enum("低", "一般", "重要", "速報") var news_importance: int = 1

func get_resolved_channel() -> int:
	if int(story_channel) != StoryChannel.MANUAL:
		return int(story_channel)
	return _channel_from_trigger_context(int(trigger_context))

func has_dialogue() -> bool:
	return dialogue != null and not dialogue.lines.is_empty()

func should_settle_affection() -> bool:
	if int(affection_settlement) == AffectionSettlement.NONE:
		return false
	if not affection_targets.is_empty():
		return true
	return character_id.strip_edges() != "" and affection_delta != 0

func get_cooldown_flag_key() -> String:
	return "story.cooldown.%s" % event_id.strip_edges()

func validate_config() -> String:
	var channel: int = get_resolved_channel()
	if channel == StoryChannel.FOLLOW and facility_id.strip_edges() != "":
		return "%s：跟隨通道不應填 facility_id（探班專用）。" % event_id
	if channel == StoryChannel.VISIT and task_signature.strip_edges() != "" and location_id.strip_edges() == "":
		pass
	if int(arc_type) == StoryArcType.DUO_ONCE and owner.strip_edges() == "":
		return "%s：duo 事件應填 owner（duo:artist_A+artist_B）。" % event_id
	if not affection_targets.is_empty() and int(affection_settlement) == AffectionSettlement.NONE:
		return "%s：有 affection_targets 時 settlement 不可為 NONE。" % event_id
	return ""

func sync_legacy_trigger_context_from_channel() -> void:
	match get_resolved_channel():
		StoryChannel.FOLLOW:
			trigger_context = TriggerContext.FOLLOW
		StoryChannel.VISIT:
			trigger_context = TriggerContext.VISIT
		StoryChannel.MEETING:
			trigger_context = TriggerContext.MEETING
		StoryChannel.ANY:
			trigger_context = TriggerContext.ANY
		_:
			trigger_context = TriggerContext.MANUAL

func _channel_from_trigger_context(context: int) -> int:
	match context:
		TriggerContext.FOLLOW:
			return StoryChannel.FOLLOW
		TriggerContext.VISIT:
			return StoryChannel.VISIT
		TriggerContext.MEETING:
			return StoryChannel.MEETING
		TriggerContext.ANY:
			return StoryChannel.ANY
		_:
			return StoryChannel.MANUAL
