extends Node

## 記者 NPC（reporter_01 狗仔、reporter_02 正面記者）。
## 與秘書相同：由專管 Autoload 載入，不走 NpcManager。

const REPORTER_01_ID: String = "reporter_01" ## 狗仔
const REPORTER_02_ID: String = "reporter_02" ## 正面記者

const REPORTER_DATA_PATHS: Dictionary = {
	REPORTER_01_ID: "res://data/npcs/reporter_01/npc_reporter_01.tres",
	REPORTER_02_ID: "res://data/npcs/reporter_02/npc_reporter_02.tres",
}

var _cache: Dictionary = {}

func _ready() -> void:
	_preload_all()
	print("[ReporterManager] 記者 NPC 就緒。")

func _preload_all() -> void:
	for reporter_id in REPORTER_DATA_PATHS.keys():
		_ensure_loaded(reporter_id)

func is_reporter_id(character_id: String) -> bool:
	return character_id.strip_edges() in REPORTER_DATA_PATHS

func get_all_reporter_ids() -> Array[String]:
	var ids: Array[String] = []
	for reporter_id in REPORTER_DATA_PATHS.keys():
		ids.append(str(reporter_id))
	return ids

func get_paparazzi_id() -> String:
	return REPORTER_01_ID

func get_press_reporter_id() -> String:
	return REPORTER_02_ID

func get_reporter_resource(reporter_id: String) -> NPCResource:
	var clean_id: String = reporter_id.strip_edges()
	if not is_reporter_id(clean_id):
		return null
	return _ensure_loaded(clean_id)

func get_display_name(reporter_id: String) -> String:
	var resource: NPCResource = get_reporter_resource(reporter_id)
	if resource != null and resource.npc_name.strip_edges() != "":
		return resource.npc_name.strip_edges()
	return reporter_id.strip_edges()

func get_avatar(reporter_id: String) -> Texture2D:
	var resource: NPCResource = get_reporter_resource(reporter_id)
	if resource == null:
		return null
	if resource.avatar != null:
		return resource.avatar
	return CharacterVisualPaths.try_load_texture(CharacterVisualPaths.avatar_path(reporter_id))

func get_portrait(reporter_id: String) -> Texture2D:
	var resource: NPCResource = get_reporter_resource(reporter_id)
	if resource == null:
		return null
	if resource.portrait != null:
		return resource.portrait
	if resource.avatar != null:
		return resource.avatar
	return CharacterVisualPaths.try_load_texture(CharacterVisualPaths.portrait_path(reporter_id))

func _ensure_loaded(reporter_id: String) -> NPCResource:
	var clean_id: String = reporter_id.strip_edges()
	if _cache.has(clean_id):
		return _cache[clean_id]
	var path: String = str(REPORTER_DATA_PATHS.get(clean_id, ""))
	if path == "":
		return null
	var loaded: Resource = load(path)
	if loaded is NPCResource:
		_cache[clean_id] = loaded
		return loaded
	push_warning("[ReporterManager] 無法載入記者資源：%s" % path)
	return null
