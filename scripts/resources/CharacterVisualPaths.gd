class_name CharacterVisualPaths
extends RefCounted

## 角色視覺資源路徑約定（頭像／半身立繪／CG）。
## 規格見 docs/writing/README_CHARACTER_ASSETS.md

const ROOT: String = "res://assets/characters/"

static func get_character_bucket(character_id: String) -> String:
	var clean_id: String = character_id.strip_edges()
	if clean_id.begins_with("artist_"):
		return "artists"
	if clean_id.begins_with("rival_"):
		return "rivals"
	return "npcs"

static func get_character_base_dir(character_id: String) -> String:
	var clean_id: String = character_id.strip_edges()
	if clean_id == "":
		return ""
	return "%s%s/%s/" % [ROOT, get_character_bucket(clean_id), clean_id]

static func avatar_file_name(character_id: String) -> String:
	return "%s_avatar.png" % character_id.strip_edges()

static func portrait_file_name(character_id: String) -> String:
	return "%s_portrait.png" % character_id.strip_edges()

static func cg_file_name(character_id: String, cg_key: String) -> String:
	var clean_id: String = character_id.strip_edges()
	var clean_key: String = cg_key.strip_edges()
	if clean_key == "":
		return ""
	if clean_key.begins_with("%s_cg_" % clean_id):
		return "%s.png" % clean_key
	if clean_key.begins_with("%s_" % clean_id):
		return "%s_cg_%s.png" % [clean_id, clean_key.trim_prefix("%s_" % clean_id)]
	return "%s_cg_%s.png" % [clean_id, clean_key]

static func avatar_path(character_id: String) -> String:
	var base: String = get_character_base_dir(character_id)
	if base == "":
		return ""
	return base.path_join("avatar").path_join(avatar_file_name(character_id))

static func portrait_path(character_id: String) -> String:
	var base: String = get_character_base_dir(character_id)
	if base == "":
		return ""
	return base.path_join("portrait").path_join(portrait_file_name(character_id))

static func cg_path(character_id: String, cg_key: String) -> String:
	var base: String = get_character_base_dir(character_id)
	var file_name: String = cg_file_name(character_id, cg_key)
	if base == "" or file_name == "":
		return ""
	return base.path_join("cg").path_join(file_name)

static func try_load_texture(path: String) -> Texture2D:
	if path.strip_edges() == "" or not ResourceLoader.exists(path):
		return null
	var tex: Texture2D = load(path)
	return tex if tex is Texture2D else null
