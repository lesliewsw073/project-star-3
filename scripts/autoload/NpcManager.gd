extends Node

## 劇情 NPC（npc_*）：具名、可好感、常駐設施或劇情觸發。
## 秘書（secretary）由 SecretaryManager 專管，不在此註冊。

const NPCS_DIR: String = "res://data/npcs/"
const NPC_ID_PREFIX: String = "npc_"
const SECRETARY_ID: String = "secretary"
const SPECIAL_NPC_IDS: Array[String] = ["secretary", "reporter_01", "reporter_02"]

var all_npcs: Dictionary = {}

func _ready() -> void:
	var count: int = load_all_npcs()
	print("[NpcManager] 劇情 NPC 入冊完成，共 %d 人。" % count)

func load_all_npcs(dir_path: String = NPCS_DIR) -> int:
	all_npcs.clear()
	_load_npc_resources_in_dir(dir_path)
	return all_npcs.size()

func _load_npc_resources_in_dir(dir_path: String) -> void:
	var normalized_dir_path: String = dir_path.trim_suffix("/") + "/"
	var dir := DirAccess.open(normalized_dir_path)
	if dir == null:
		push_warning("[NpcManager] NPC 目錄不存在或為空：%s" % normalized_dir_path)
		return

	dir.list_dir_begin()
	var file_name: String = dir.get_next()
	while file_name != "":
		if dir.current_is_dir():
			if not file_name.begins_with("."):
				_load_npc_resources_in_dir(normalized_dir_path.path_join(file_name))
		else:
			var res_path: String = _normalize_resource_path(normalized_dir_path, file_name)
			if res_path != "":
				var res: Resource = load(res_path)
				if res is NPCResource:
					_register_npc(res)
		file_name = dir.get_next()
	dir.list_dir_end()

func _normalize_resource_path(dir_path: String, file_name: String) -> String:
	if file_name.ends_with(".tres"):
		return dir_path.path_join(file_name)
	if file_name.ends_with(".tres.remap"):
		return dir_path.path_join(file_name.trim_suffix(".remap"))
	return ""

func _register_npc(resource: NPCResource) -> void:
	var npc_id: String = resource.npc_id.strip_edges()
	if npc_id == "":
		push_warning("[NpcManager] 有一個 NPC 資源沒填 npc_id，已跳過。")
		return
	if npc_id == SECRETARY_ID or npc_id in SPECIAL_NPC_IDS:
		return
	if not npc_id.begins_with(NPC_ID_PREFIX):
		push_warning("[NpcManager] 劇情 NPC id 必須以 npc_ 開頭（秘書用 secretary）：%s" % npc_id)
		return
	if all_npcs.has(npc_id):
		push_warning("[NpcManager] 重複 npc_id：%s" % npc_id)
	all_npcs[npc_id] = resource

func is_story_npc_id(character_id: String) -> bool:
	return character_id.strip_edges().begins_with(NPC_ID_PREFIX)

func get_npc_resource(npc_id: String) -> NPCResource:
	var clean_id: String = npc_id.strip_edges()
	if all_npcs.has(clean_id):
		return all_npcs[clean_id]
	return null

func get_all_npc_ids() -> Array:
	return all_npcs.keys()

func get_npc_display_name(npc_id: String) -> String:
	var resource: NPCResource = get_npc_resource(npc_id)
	if resource == null:
		return npc_id.strip_edges()
	if resource.npc_name.strip_edges() != "":
		return resource.npc_name.strip_edges()
	return npc_id.strip_edges()

func get_npc_avatar(npc_id: String) -> Texture2D:
	var resource: NPCResource = get_npc_resource(npc_id)
	if resource == null:
		return null
	if resource.avatar != null:
		return resource.avatar
	return CharacterVisualPaths.try_load_texture(CharacterVisualPaths.avatar_path(npc_id))

func get_npc_portrait(npc_id: String) -> Texture2D:
	var resource: NPCResource = get_npc_resource(npc_id)
	if resource == null:
		return null
	if resource.portrait != null:
		return resource.portrait
	if resource.avatar != null:
		return resource.avatar
	return CharacterVisualPaths.try_load_texture(CharacterVisualPaths.portrait_path(npc_id))

func get_npc_initial_affection(npc_id: String) -> int:
	var resource: NPCResource = get_npc_resource(npc_id)
	if resource == null or not resource.can_gain_affection:
		return 0
	if resource.default_affection > 0:
		return clampi(
			resource.default_affection,
			RelationshipManager.MIN_AFFECTION,
			RelationshipManager.MAX_AFFECTION
		)
	return CharacterDatabase.DEFAULT_NON_PLAYER_AFFECTION

func get_npcs_for_facility(facility_id: String) -> Array[NPCResource]:
	var clean_facility_id: String = facility_id.strip_edges()
	var results: Array[NPCResource] = []
	for npc_id in all_npcs:
		var resource: NPCResource = all_npcs[npc_id]
		if resource == null:
			continue
		if resource.home_facility_id.strip_edges() == clean_facility_id:
			results.append(resource)
	return results
