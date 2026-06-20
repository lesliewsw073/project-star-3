extends Node

## 秘書：邏輯 id 固定 secretary（與 npc 視覺資源分離）。
## 顯示名／頭像讀 data/npcs/secretary/npc_secretary.tres。

const SECRETARY_ID: String = "secretary"
const SECRETARY_DATA_PATH: String = "res://data/npcs/secretary/npc_secretary.tres"

@export var base_data: NPCResource

var hidden_flags: Dictionary = {
	"saved_company_once": false,
	"never_exploited": true,
}

func _ready() -> void:
	_ensure_base_data()

func _ensure_base_data() -> void:
	if base_data != null:
		return
	var loaded: Resource = load(SECRETARY_DATA_PATH)
	if loaded is NPCResource:
		base_data = loaded
	else:
		push_warning("[SecretaryManager] 無法載入秘書資源：%s" % SECRETARY_DATA_PATH)

func get_display_name() -> String:
	_ensure_base_data()
	if base_data != null and base_data.npc_name.strip_edges() != "":
		return base_data.npc_name.strip_edges()
	return "小唯"

func get_avatar() -> Texture2D:
	_ensure_base_data()
	if base_data == null:
		return null
	if base_data.avatar != null:
		return base_data.avatar
	return CharacterVisualPaths.try_load_texture(CharacterVisualPaths.avatar_path(SECRETARY_ID))

func get_portrait() -> Texture2D:
	_ensure_base_data()
	if base_data == null:
		return null
	if base_data.portrait != null:
		return base_data.portrait
	if base_data.avatar != null:
		return base_data.avatar
	return CharacterVisualPaths.try_load_texture(CharacterVisualPaths.portrait_path(SECRETARY_ID))

func generate_weekly_advice() -> Array[String]:
	var advices: Array[String] = []

	for artist_id in ArtistManager.roster:
		var artist = ArtistManager.roster[artist_id]
		if artist == null:
			continue
		var artist_name = artist.base_data.artist_name

		if artist.health.current_state != ArtistHealthComponent.PhysicalState.HEALTHY:
			advices.append("老板，%s 的身体数据亮红灯了，这周必须安排休息或者去疗养院！" % artist_name)

		if artist.mood.current_state == ArtistMoodComponent.MoodState.RED:
			advices.append("警报！%s 的压力值快爆表了，随时可能罢工，请立刻干预！" % artist_name)

	if advices.is_empty():
		advices.append("老板，本周各部门运转良好，大家的状态都很棒哦！")

	return advices

func get_affection() -> int:
	return RelationshipManager.get_affection(SECRETARY_ID)

func add_affection(amount: int) -> void:
	RelationshipManager.add_affection(SECRETARY_ID, amount)

func check_secretary_hidden_ending(has_artist_romance: bool) -> bool:
	if has_artist_romance:
		return false

	if get_affection() < 100:
		return false

	for flag in hidden_flags.values():
		if flag == false:
			return false

	return true
