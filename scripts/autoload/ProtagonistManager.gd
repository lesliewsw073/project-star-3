extends Node

const PROTAGONIST_ID: String = "protagonist"
const DEFAULT_LAST_NAME: String = "陸"
const DEFAULT_FIRST_NAME: String = "星河"
const DEFAULT_TITLE: String = "製作人"
const FIRST_NAME_AFFECTION_THRESHOLD: int = 70

var last_name: String = DEFAULT_LAST_NAME
var first_name: String = DEFAULT_FIRST_NAME
var default_title: String = DEFAULT_TITLE
var nickname: String = ""
var profile_locked: bool = false

func _ready() -> void:
	print("[ProtagonistManager] 就绪，当前主角: ", get_full_name())

func rename(new_last_name: String, new_first_name: String) -> bool:
	if profile_locked:
		push_warning("[ProtagonistManager] 主角姓名已鎖定，無法修改。")
		return false
	var clean_last_name: String = new_last_name.strip_edges()
	var clean_first_name: String = new_first_name.strip_edges()
	if clean_last_name == "" or clean_first_name == "":
		push_warning("[ProtagonistManager] 改名失败：姓氏和名字都不能为空。")
		return false

	last_name = clean_last_name
	first_name = clean_first_name
	return true

func lock_profile() -> void:
	profile_locked = true

func is_profile_locked() -> bool:
	return profile_locked

func set_nickname(new_nickname: String) -> void:
	nickname = new_nickname.strip_edges()

func get_full_name() -> String:
	return last_name + first_name

func get_last_name() -> String:
	return last_name

func get_first_name() -> String:
	return first_name

func get_default_title() -> String:
	return default_title

func get_formal_title() -> String:
	return "%s%s" % [last_name, default_title]

func get_last_name_with_suffix(suffix: String = "先生") -> String:
	return "%s%s" % [last_name, suffix]

func get_preferred_address(affection: int = 0, special_address: String = "") -> String:
	if special_address.strip_edges() != "":
		return special_address.strip_edges()
	if nickname != "" and affection >= FIRST_NAME_AFFECTION_THRESHOLD:
		return nickname
	if affection >= FIRST_NAME_AFFECTION_THRESHOLD:
		return first_name
	return get_formal_title()

func export_save_state() -> Dictionary:
	return {
		"last_name": last_name,
		"first_name": first_name,
		"default_title": default_title,
		"nickname": nickname,
		"profile_locked": profile_locked,
	}

func import_save_state(data: Dictionary) -> void:
	last_name = str(data.get("last_name", DEFAULT_LAST_NAME))
	first_name = str(data.get("first_name", DEFAULT_FIRST_NAME))
	default_title = str(data.get("default_title", DEFAULT_TITLE))
	nickname = str(data.get("nickname", ""))
	profile_locked = bool(data.get("profile_locked", profile_locked))
	var has_non_default_name: bool = (
		last_name.strip_edges() != DEFAULT_LAST_NAME
		or first_name.strip_edges() != DEFAULT_FIRST_NAME
	)
	if not profile_locked and has_non_default_name:
		profile_locked = true
