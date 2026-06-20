extends Node

## 競爭對手（rival_NNN）：不可簽約，掛名其他經紀公司，參與通告／頒獎等競爭。
## 資源結構复用 ArtistResource；id 固定 rival_ 前綴。

const RIVALS_DIR: String = "res://data/rivals/"
const RIVAL_ID_PREFIX: String = "rival_"

var all_rivals: Dictionary = {}

func _ready() -> void:
	var count: int = load_all_rivals()
	print("[RivalManager] 競爭對手入冊完成，共 %d 人。" % count)

func load_all_rivals(dir_path: String = RIVALS_DIR) -> int:
	all_rivals.clear()
	_load_rival_resources_in_dir(dir_path)
	return all_rivals.size()

func _load_rival_resources_in_dir(dir_path: String) -> void:
	var normalized_dir_path: String = dir_path.trim_suffix("/") + "/"
	var dir := DirAccess.open(normalized_dir_path)
	if dir == null:
		push_warning("[RivalManager] 競爭對手目錄不存在或為空：%s" % normalized_dir_path)
		return

	dir.list_dir_begin()
	var file_name: String = dir.get_next()
	while file_name != "":
		if dir.current_is_dir():
			if not file_name.begins_with("."):
				_load_rival_resources_in_dir(normalized_dir_path.path_join(file_name))
		else:
			var res_path: String = _normalize_resource_path(normalized_dir_path, file_name)
			if res_path != "":
				var res: Resource = load(res_path)
				if res is ArtistResource:
					_register_rival(res)
		file_name = dir.get_next()
	dir.list_dir_end()

func _normalize_resource_path(dir_path: String, file_name: String) -> String:
	if file_name.ends_with(".tres"):
		return dir_path.path_join(file_name)
	if file_name.ends_with(".tres.remap"):
		return dir_path.path_join(file_name.trim_suffix(".remap"))
	return ""

func _register_rival(resource: ArtistResource) -> void:
	var rival_id: String = resource.artist_id.strip_edges()
	if rival_id == "":
		push_warning("[RivalManager] 有一個對手資源沒填 artist_id（應為 rival_NNN），已跳過。")
		return
	if not rival_id.begins_with(RIVAL_ID_PREFIX):
		push_warning("[RivalManager] 對手 id 必須以 rival_ 開頭：%s" % rival_id)
		return
	if all_rivals.has(rival_id):
		push_warning("[RivalManager] 重複 rival_id：%s" % rival_id)
	all_rivals[rival_id] = resource

func is_rival_id(character_id: String) -> bool:
	return character_id.strip_edges().begins_with(RIVAL_ID_PREFIX)

func get_rival_resource(rival_id: String) -> ArtistResource:
	var clean_id: String = rival_id.strip_edges()
	if all_rivals.has(clean_id):
		return all_rivals[clean_id]
	return null

func get_all_rival_ids() -> Array:
	return all_rivals.keys()

func get_rival_avatar(rival_id: String) -> Texture2D:
	var resource: ArtistResource = get_rival_resource(rival_id)
	if resource == null:
		return null
	if resource.avatar != null:
		return resource.avatar
	return CharacterVisualPaths.try_load_texture(CharacterVisualPaths.avatar_path(rival_id))

func get_rival_portrait(rival_id: String) -> Texture2D:
	var resource: ArtistResource = get_rival_resource(rival_id)
	if resource == null:
		return null
	if resource.portrait != null:
		return resource.portrait
	if resource.avatar != null:
		return resource.avatar
	return CharacterVisualPaths.try_load_texture(CharacterVisualPaths.portrait_path(rival_id))

func get_rival_agency_id(rival_id: String) -> String:
	var resource: ArtistResource = get_rival_resource(rival_id)
	if resource == null:
		return ""
	return resource.home_agency_id.strip_edges()

func get_rival_agency_name(rival_id: String) -> String:
	var agency_id: String = get_rival_agency_id(rival_id)
	if agency_id == "":
		return ""
	return AgencyDatabase.get_agency_display_name(agency_id)

func get_rival_profile(rival_id: String) -> ArtistProfileResource:
	var resource: ArtistResource = get_rival_resource(rival_id)
	if resource == null:
		return null
	return resource.get_character_profile()
